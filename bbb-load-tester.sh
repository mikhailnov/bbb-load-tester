#!/bin/bash

set -efu
set -o pipefail
set -x
set -a

# mod 0600
umask 0077

PATH="$PWD:/usr/libexec/bbb-load-tester:$PATH"
if test -e "$PWD"/bbb_v2.4_webcam_button.png
then
	BUTTONS_DIR="$PWD"
else
	BUTTONS_DIR=/usr/share/bbb-load-tester
fi

CHROMIUM="${CHROMIUM:-chromium-browser}"
SLEEP_KOEF="${SLEEP_KOEF:-1}"
# wide enough to avoid automatic collapsing of chat etc., it will change number of tabs by xdotool
WINDOW_WIDTH="${WINDOW_WIDTH:-1270}"
WINDOW_HEIGHT="${WINDOW_HEIGHT:-720}"

URL="${URL:-}"
if [ -z "$URL" ]; then
	# shellcheck disable=SC2016
	echo 'Set $URL to URL of login page!'
	exit 1
fi

NUM="${NUM:-}"
if [ -z "$NUM" ] || ! [ "$NUM" -gt 0 ]; then
	# shellcheck disable=SC2016
	echo 'Set $NUM to an integer (>0) number of emulated users!'
	exit 1
fi

XSERVER="${XSERVER:-}"
case "$XSERVER" in
	Xephyr ) : ;;
	Xvfb ) : ;;
	* )
		# shellcheck disable=SC2016
		echo 'Set $XSERVER to Xephyr or Xvfb!'
		exit 1
	;;
esac

# + python3-opencv
for i in \
	bc \
	"$CHROMIUM" \
	pactl \
	scrot \
	xdotool \
	"$XSERVER" \
	xfwm4
do
	if ! command -v "$i" >/dev/null 2>&1; then
		echo "Install $i !"
		exit 1
	fi
done

AUDIO_MODE="${AUDIO_MODE:-}"
case "$AUDIO_MODE" in
	"listen-only" ) : ;;
	"real-microphone" ) : ;;
	"virtual-microphone" ) : ;;
	* )
		# shellcheck disable=SC2016
		echo 'Set $AUDIO_MODE to listen-only or real-microphone of virtual-microphone!'
		exit 1
	;;
esac

VIDEO_MODE="${VIDEO_MODE:-}"
case "$VIDEO_MODE" in
	"no-webcam" ) : ;;
	"real-webcam" ) : ;;
	"virtual-webcam" ) : ;;
	* )
		# shellcheck disable=SC2016
		echo 'Set $VIDEO_MODE to no-webcam or real-webcam!'
		exit 1
	;;
esac

SESSION_TYPE="${SESSION_TYPE:-}"
session_func=""
case "$SESSION_TYPE" in
	"greenlight" )
		session_func=_open_bbb_session_greenlight
	;;
	"dumalogiya-wp" )
		session_func=_open_bbb_session_dumalogiya
		if [ -z "${DUMALOGIYA_PASSWORD:-}" ]; then
			# shellcheck disable=SC2016
			echo 'Set $DUMALOGIYA_PASSWORD!'
			exit 1
		fi
	;;
	* )
		# shellcheck disable=SC2016
		echo 'Set $SESSION_TYPE to greenlight or dumalogiya-wp!'
		exit 1
	;;
esac

TMPDIR="$(mktemp -d)"
export TMPDIR
PID_LIST="$(mktemp)"

virtual_pulseaudio_sink_number=""
_cleanup(){
	for i in $(tac "$PID_LIST")
	do
		kill "$i" 2>/dev/null || :
		kill -9 "$i" 2>/dev/null || :
	done
	if [ -n "$virtual_pulseaudio_sink_number" ]; then
		pactl unload-module "$virtual_pulseaudio_sink_number" || :
	fi
	rm -fr "$TMPDIR"
}
trap '_cleanup' EXIT

_sleep(){
	local a="$1"
	sleep $((a*SLEEP_KOEF))
}

# Run a process in detached form
# We can use systemd-run here, but let's keep things simplier and crossplatform for now.
# Linux and DragonFlyBSD have /proc/$PID by default,
# FreeBSD does not have /proc by default, but it can be turned on.
# https://stackoverflow.com/a/1024937
_run(){
	"$@" &
	local PID=$!
	_sleep 1
	if [ ! -d /proc/"$PID" ]; then
		echo "command $* has probably failed"
		return 1
	fi
	echo "$PID" >> "$PID_LIST"
}

_gen_virt_display(){
	local d
	while true
	do
		d=$(( ( RANDOM % 5000 )  + 1 ))
		# XXX /tmp/.X11-unix may be different in theory,
		# I don't know how to find this directory
		if ! test -e /tmp/.X11-unix/X"$d" ; then
			d=:"$d"
			break
		fi
	done
	echo "$d"
}

# $1: resolution
# $2: screen
# example: _xserver_start 1024x720 :10
_xserver_start(){
	case "$XSERVER" in
		Xephyr ) _run Xephyr -br -ac -noreset -screen "$1" "$2" ;;
		Xvfb ) _run Xvfb "$2" -screen 0 "$1"x24 ;;
	esac
	DISPLAY="$2" _run xfwm4
}

# $1: X display (Xephyr)
# $2: URL
# $3: directory with Chromium profile
_open_bbb_session_dumalogiya(){
	local X="$1"
	DISPLAY="$X" xdotool key Tab Tab Tab
	DISPLAY="$X" xdotool type "Load"
	DISPLAY="$X" xdotool key Tab
	DISPLAY="$X" xdotool type "Testing ($X)"
	DISPLAY="$X" xdotool key Tab
	DISPLAY="$X" xdotool type "$DUMALOGIYA_PASSWORD"
	DISPLAY="$X" xdotool key Return
}

# $1: X display (Xephyr)
# $2: URL
# $3: directory with Chromium profile
_open_bbb_session_greenlight(){
	local X="$1"
	DISPLAY="$X" xdotool type "Load Testing ($X)"
	DISPLAY="$X" xdotool key Return
}

# $1: X display
_mk_screenshot(){
	local file
	file="$(mktemp --suffix=.png)"
	# workaround scrot not saving anything if file already exists
	unlink "$file"
	DISPLAY="$1" scrot --quality 100 "$file"
	echo "$file"
}

# $1: X display
# $2: screenshot
# $3: image to find inside the screenshot
# $4: offset of x coordinate (usually 0)
# $5: offset of y coordinate (usually 0)
_click_center_of_image(){
	local center
	center="$(find-center.py "$2" "$3")"
	[ -n "$center" ] || return 1
	local center_x
	center_x="$(echo "$center" | cut -d ' ' -f1)"
	center_x="$(echo "${center_x}+${4}" | bc)"
	[ -n "$center_x" ] || return 1
	local center_y
	center_y="$(echo "$center" | cut -d ' ' -f2)"
	center_y="$(echo "${center_y}+${5}" | bc)"
	[ -n "$center_y" ] || return 1
	DISPLAY="$1" xdotool mousemove "$center_x" "$center_y" click 1
}

# $1: X display
# $2: image to find inside the screen
# $3: offset of x coordinate (usually 0)
# $4: offset of y coordinate (usually 0)
_click_by_image(){
	local screenshot
	screenshot="$(_mk_screenshot "$1")"
	_click_center_of_image "$1" "$screenshot" "$2" "$3" "$4"
}

# $1: X display (Xephyr)
_setup_bbb_session(){
	local audio_mode_img
	case "$AUDIO_MODE" in
		listen-only )
			audio_mode_img="$BUTTONS_DIR/bbb_v2.4_listen.png"
		;;
		real-microphone | virtual-microphone )
			audio_mode_img="$BUTTONS_DIR/bbb_v2.4_microphone.png"
		;;
	esac
	_click_by_image "$1" "$audio_mode_img" 0 0
	_sleep 2
	if [ "$AUDIO_MODE" = real-microphone ] || [ "$AUDIO_MODE" = virtual-microphone ]; then
		# allow to use microphone in the browser
		DISPLAY="$1" xdotool key Tab Tab Tab Return
		_sleep 5
		# confirm that sound is heard
		_click_by_image "$1" "$BUTTONS_DIR/bbb_v2.4_hear_yes.png" 0 0
		_sleep 3
	fi
	if [ "$VIDEO_MODE" = real-webcam ] || [ "$VIDEO_MODE" = virtual-webcam ] ; then
		# Trigger webcam dialog
		# Clicking Tab works not reliably for webcams, different number of tabs is needed
		# from time to time and in different versions of BigBlueButton, so using opencv to find button coordinates
		# Take shot of full virtual (Xephyr) screen
		_click_by_image "$1" "$BUTTONS_DIR"/bbb_v2.4_webcam_button.png 0 0
		_sleep 5
		# allow webcam in the browser
		DISPLAY="$1" xdotool key Tab Tab Tab Return
		_sleep 3 #find-center.py will take a few seconds
		# start webcam (click the blue button inside webcam dialog)
		_click_by_image "$1" "$BUTTONS_DIR"/bbb_v2.4_webcam_dialog_corner.png 0 -72
		_sleep 3
	fi
}

# $1: sink name
# This works with both pulseaudio and pipewire
_setup_virtual_sound(){
	local sink
	if ! sink="$(pactl load-module module-null-sink sink_name="$1")" ; then
		return $?
	fi
	echo "$sink"
}

# XXX For now just disconnect all real webcams to make the virtual one be the only
# and default choice in Chromium. In theory bubblewrap can be used to override /dev/video* for Chromium.
_setup_virtual_camera(){
	# We modprobe v4l2loopback via configs in /etc
	# sudo modprobe v4l2loopback exclusive_caps=1 devices=1 video_nr=55 card_label="bbb-load-tester virtual webcam" max_width=640 max_height=480 max_openers=100
	_run env WEBCAM=/dev/video55 ondemandcam
}

_main(){
	if [ "$AUDIO_MODE" = virtual-microphone ]; then
		local rand
		rand="$(base64 /dev/urandom | head -c 5 || :)"
		if ! virtual_pulseaudio_sink_number="$(_setup_virtual_sound "nullsink_${rand}")"; then
			echo "Failed to setup virtual audio source!"
			return 1
		fi
		# chromium will read it
		export PULSE_SOURCE="nullsink_${rand}.monitor"
		export PULSE_SINK="nullsink_${rand}"
	fi
	if [ "$VIDEO_MODE" = virtual-webcam ]; then
		_setup_virtual_camera
	fi
	local X
	X="$(_gen_virt_display)"
	local chromium_profile_dir
	chromium_profile_dir="$(mktemp -d)"
	# start X server and a window manager inside it
	_xserver_start "$WINDOW_WIDTH"x"$WINDOW_HEIGHT" "$X"
	# start web-browser inside that X server
	DISPLAY="$X" _run "$CHROMIUM" \
		--new-window \
		--start-maximized \
		--no-default-browser-check \
		--user-data-dir="$chromium_profile_dir" \
		"about:blank" \
		2>/dev/null
	_sleep 5
	for i in $(seq 1 "$NUM")
	do
		# open a new tab in already launched Chromium
		DISPLAY="$X" "$CHROMIUM" --user-data-dir="$chromium_profile_dir" --new-tab "$URL"
		# wait for it to load
		_sleep 6
		# login into BigBlueButton
		"$session_func" "$X" "$URL" "$chromium_profile_dir"
		_sleep 15
		# start audio and/or video inside that BigBlueButton client
		_setup_bbb_session "$X"
	done
	# do nothing continiously
	{ set +x; while :; do :; done ;}
}

_main "$@"

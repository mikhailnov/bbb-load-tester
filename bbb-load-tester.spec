# spec file for in-source build on ROSA Linux
# rpmbuild --define "_sourcedir $PWD" -bb bbb-load-tester.spec

Name: bbb-load-tester
Summary: Script to stress-test BigBlueButton
License: GPLv3
Group: Sound
Version: 1.1
Release: 1
Url: https://github.com/mikhailnov/bbb-load-tester
Source1: CMakeLists.txt
Source2: bbb-load-tester.sh
Source3: bbb-load-tester.spec
Source4: bbb_v2.4_hear_no.png
Source5: bbb_v2.4_hear_yes.png
Source6: bbb_v2.4_listen.png
Source7: bbb_v2.4_microphone.png
Source8: bbb_v2.4_webcam_button.png
Source9: bbb_v2.4_webcam_dialog_corner.png
Source10: find-center.py
Source11: ondemandcam.c
BuildRequires: cmake
Requires: bash
Requires: bc
Requires: python3-opencv
Requires: %{_bindir}/chromium-browser
Requires: %{_bindir}/pactl
Requires: scrot
Requires: xclip
Requires: xdotool
Requires: %{_bindir}/Xvfb
Requires: %{_bindir}/Xephyr
Requires: %{_bindir}/xrandr
Requires: xfwm4

%description
Script to stress-test BigBlueButton.
Opens a Chromium-based browser with BigBlueButton clients.

%files
%{_bindir}/bbb-load-tester
%{_libexecdir}/bbb-load-tester
%{_datadir}/bbb-load-tester

#----------------------------------------------------------

%prep
cp %sources .

%build
%cmake
%make

%install
%makeinstall_std -C build

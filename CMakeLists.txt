# XXX I am not a cmake programmer, maybe this crap is incorrect

cmake_minimum_required(VERSION 3.0)

# build ondemandcam
project(bbb-load-tester C)
add_executable(ondemandcam ondemandcam.c)
target_link_libraries(ondemandcam -lrt -lpthread)
install(TARGETS ondemandcam DESTINATION /usr/libexec/bbb-load-tester)
# 0755 in cmake crappy language
install(FILES find-center.py DESTINATION /usr/libexec/bbb-load-tester PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ)
install(FILES bbb-load-tester.sh RENAME bbb-load-tester DESTINATION ${CMAKE_INSTALL_PREFIX}/bin PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ)
# 0644
install(FILES
        bbb_v2.4_hear_no.png
        bbb_v2.4_hear_yes.png
        bbb_v2.4_listen.png
        bbb_v2.4_microphone.png
        bbb_v2.4_webcam_button.png
        bbb_v2.4_webcam_dialog_corner.png
        DESTINATION /usr/share/bbb-load-tester)

# build gui
add_subdirectory(gui)

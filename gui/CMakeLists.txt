# https://gist.github.com/fracek/3323924
# https://stackoverflow.com/a/36292448

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
add_executable(bbb-load-tester-gui main.c)
include_directories(${GTK3_INCLUDE_DIRS})
link_directories(${GTK3_LIBRARY_DIRS})
add_definitions(${GTK3_CFLAGS_OTHER})
target_link_libraries(bbb-load-tester-gui ${GTK3_LIBRARIES})

install(TARGETS bbb-load-tester-gui DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

# bbb-load-tester-gui.svg is from https://www.iconfinder.com/icons/4417092/download/svg/4096
# XXX Can /usr/share be accessed from a special variable?
install(FILES bbb-load-tester-gui.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons)
install(FILES bbb-load-tester-gui.desktop DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications)

# https://gist.github.com/fracek/3323924
# https://stackoverflow.com/a/36292448

project(bbb-load-tester-gui C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
add_executable(bbb-load-tester-gui main.c)
include_directories(${GTK3_INCLUDE_DIRS})
link_directories(${GTK3_LIBRARY_DIRS})
add_definitions(${GTK3_CFLAGS_OTHER})
target_link_libraries(bbb-load-tester-gui ${GTK3_LIBRARIES})

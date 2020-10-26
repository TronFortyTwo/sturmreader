set(PLUGIN_DIR Gettext)

set(gettext_SRCS
	gettexttr.cpp
	gettextplugin.cpp
)

set(CMAKE_AUTOMOC ON)

add_library(gettextplugin MODULE ${gettext_SRCS})

target_compile_options(gettextplugin PRIVATE -Werror -Wall -Wextra)
qt5_use_modules(gettextplugin Qml Quick DBus)
# Copy the plugin file to the build dir
set_target_properties(gettextplugin PROPERTIES
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../${PLUGIN_DIR}
)
target_link_libraries(gettextplugin
	${Intl_LIBRARIES}
	#intl
)

execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
    OUTPUT_VARIABLE ARCH_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Copy the qmldir file to the build dir
add_custom_command(TARGET gettextplugin POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/qmldir ${CMAKE_CURRENT_BINARY_DIR}/../${PLUGIN_DIR}
)

# Install plugin file
string(REPLACE "//" "/" LIB_DIR ${DATA_DIR}/${PLUGIN_DIR})
install(TARGETS gettextplugin DESTINATION ${LIB_DIR})
install(FILES qmldir DESTINATION ${LIB_DIR})

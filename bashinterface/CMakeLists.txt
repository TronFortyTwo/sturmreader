set(PLUGIN_DIR Bashinterface)

set(Bashinterface_SRCS
    Bashinterface.cpp
    Bashinterfaceplugin.cpp
)

add_library(bashinterfaceplugin MODULE
    ${fontlister_SRCS}
)

qt5_use_modules(bashinterfaceplugin Qml Quick)

# Copy the plugin file to the build dir
set_target_properties(bashinterfaceplugin PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../${PLUGIN_DIR}
)

# Copy the qmldir file to the build dir
add_custom_command(TARGET bashinterfaceplugin POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/qmldir ${CMAKE_CURRENT_BINARY_DIR}/../${PLUGIN_DIR}
)

# Install plugin file
string(REPLACE "//" "/" LIB_DIR ${DATA_DIR}/${PLUGIN_DIR})
install(TARGETS bashinterfaceplugin DESTINATION ${LIB_DIR})
install(FILES qmldir DESTINATION ${LIB_DIR})

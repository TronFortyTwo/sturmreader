set(PLUGIN_DIR Bashinterface)
set(PLUGIN "Bashinterface")

set(bashinterface_SRCS
    bashinterface.cpp
    bashinterfaceplugin.cpp
)

add_library(${PLUGIN} MODULE
    ${bashinterface_SRCS}
)

qt5_use_modules(${PLUGIN} Qml Quick DBus)

# Copy the plugin file to the build dir
set_target_properties(${PLUGIN} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../${PLUGIN_DIR}
)

# Copy the qmldir file to the build dir
add_custom_command(TARGET ${PLUGIN} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/qmldir ${CMAKE_CURRENT_BINARY_DIR}/../${PLUGIN_DIR}
)

# Install plugin file
string(REPLACE "//" "/" LIB_DIR ${DATA_DIR}/${PLUGIN_DIR})
install(TARGETS ${PLUGIN} DESTINATION ${LIB_DIR})
install(FILES qmldir DESTINATION ${LIB_DIR})

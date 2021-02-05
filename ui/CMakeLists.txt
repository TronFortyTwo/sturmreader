cmake_minimum_required(VERSION 3.0.0)

set(CMAKE_AUTOMOC ON)

set(UI_SRC_FILES
	# this has to be kept for various stuff
	sturmreader.svg
)

if(${OUT_OF_TREE_BUILD})
    foreach( SRC_FILE ${UI_SRC_FILES} )
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${SRC_FILE})
    endforeach( SRC_FILE )
endif(${OUT_OF_TREE_BUILD})

set(IMAGE_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/images/stainedpaper_tiled.jpg
)

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/qml/Textures.qml
	# Maybe we should go back to outputting it to the build directory
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/qml/encoder.sh ${IMAGE_SRC} > ${CMAKE_CURRENT_SOURCE_DIR}/qml/Textures.qml
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS ${IMAGE_SRC}
)
add_custom_target(MakeTextures ALL DEPENDS qml/Textures.qml)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} DESTINATION ${DATA_DIR}
    PATTERN "[Cc][Mm]ake*" EXCLUDE)

#add_subdirectory(html)

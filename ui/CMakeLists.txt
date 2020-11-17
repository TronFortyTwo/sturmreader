cmake_minimum_required(VERSION 3.0.0)

set(CMAKE_AUTOMOC ON)

set(UI_SRC_FILES

	About.qml
	BookPage.qml
	DefaultCover.qml
	historystack.js
	ImportPage.qml
	LocalBooks.qml
	main.qml
	Reader.qml
	Server.qml
	Scaling.qml
	
	not-portable/Metrics.qml
	not-portable/Importer.qml

	components/FloatingButton.qml
	components/SwipeControl.qml
	components/Action.qml
	components/Icon.qml

	images/error_cover.svg
	images/error_cover_full.svg

	Icons/add.svg
	Icons/book.svg
	Icons/go-home.svg
	Icons/go-next.svg
	Icons/go-previous.svg
	Icons/info.svg
	Icons/ok.svg
	Icons/redo.svg
	Icons/refresh.svg
	Icons/settings.svg
	Icons/undo.svg
	Icons/COPYING
)

if(${OUT_OF_TREE_BUILD})
    foreach( SRC_FILE ${UI_SRC_FILES} )
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${SRC_FILE})
    endforeach( SRC_FILE )
endif(${OUT_OF_TREE_BUILD})

set(IMAGE_SRC
    images/stainedpaper_tiled.jpg
)

add_executable(sturmreader main.cpp gettext.cpp units.cpp ${QT_RESOURCES})
qt5_use_modules(sturmreader Gui Qml Quick QuickControls2)
install(TARGETS sturmreader RUNTIME DESTINATION ${DATA_DIR})


add_custom_command(OUTPUT Textures.qml
    COMMAND ./encoder.sh ${IMAGE_SRC} > ${CMAKE_CURRENT_BINARY_DIR}/Textures.qml
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS ${IMAGE_SRC}
)
add_custom_target(MakeTextures ALL DEPENDS Textures.qml)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} DESTINATION ${DATA_DIR}
    PATTERN "[Cc][Mm]ake*" EXCLUDE)

cmake_minimum_required(VERSION 3.0.0)

set(CMAKE_AUTOMOC ON)

set(UI_SRC_FILES

	qml/About.qml
	qml/BookPage.qml
	qml/DefaultCover.qml
	qml/historystack.js
	qml/ImportPage.qml
	qml/LocalBooks.qml
	qml/Main.qml
	qml/Reader.qml
	qml/Server.qml
	qml/Scaling.qml
	qml/FloatingButton.qml
	qml/SwipeControl.qml
	qml/Action.qml
	qml/Icon.qml
	qml/ImporterUT.qml
	qml/ImporterPortable.qml
	qml/MetricsUT.qml
	qml/MetricsPortable.qml
	qml/Colors.qml
	qml/Settings.qml
	qml/CoverDelegate.qml
	qml/TitleDelegate.qml
	qml/AuthorDelegate.qml

	qml/images/error_cover.svg
	qml/images/error_cover_full.svg

	qml/Icons/add.svg
	qml/Icons/avatar.svg
	qml/Icons/book.svg
	qml/Icons/go-home.svg
	qml/Icons/go-next.svg
	qml/Icons/go-previous.svg
	qml/Icons/info.svg
	qml/Icons/ok.svg
	qml/Icons/redo.svg
	qml/Icons/refresh.svg
	qml/Icons/settings.svg
	qml/Icons/undo.svg
	qml/Icons/COPYING
	
	sturmreader.svg
)

if(${OUT_OF_TREE_BUILD})
    foreach( SRC_FILE ${UI_SRC_FILES} )
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${SRC_FILE})
    endforeach( SRC_FILE )
endif(${OUT_OF_TREE_BUILD})

set(IMAGE_SRC
    qml/images/stainedpaper_tiled.jpg
)

add_executable(sturmreader
	main.cpp
	gettext.cpp
	units.cpp
	fontlister.cpp
	filesystem.cpp
	mimetype.cpp
	qhttpserver/qhttpserver.cpp
	qhttpserver/fileserver.cpp
	qhttpserver/qhttpconnection.cpp
	qhttpserver/qhttprequest.cpp
	qhttpserver/qhttpresponse.cpp
	qhttpserver/http-parser/http_parser.c
	reader/epubreader.cpp
	reader/cbzreader.cpp
	reader/pdfreader.cpp
	reader/quazip/JlCompress.cpp
	reader/quazip/qioapi.cpp
	reader/quazip/quacrc32.cpp
	reader/quazip/quaadler32.cpp
	reader/quazip/quazip.cpp
	reader/quazip/quazipfile.cpp
	reader/quazip/quagzipfile.cpp
	reader/quazip/quazipfileinfo.cpp
	reader/quazip/quaziodevice.cpp
	reader/quazip/quazipnewinfo.cpp
	reader/quazip/unzip.c
	reader/quazip/zip.c
	${QT_RESOURCES} )
	
target_link_libraries(sturmreader poppler-qt5 ZLIB::ZLIB Qt5::Core Qt5::Gui Qt5::Qml Qt5::Xml Qt5::Quick Qt5::QuickControls2)

install(TARGETS sturmreader RUNTIME DESTINATION ${DATA_DIR})

add_custom_command(OUTPUT qml/Textures.qml
    COMMAND ./qml/encoder.sh ${IMAGE_SRC} > ${CMAKE_CURRENT_BINARY_DIR}/qml/Textures.qml
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS ${IMAGE_SRC}
)
add_custom_target(MakeTextures ALL DEPENDS qml/Textures.qml)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} DESTINATION ${DATA_DIR}
    PATTERN "[Cc][Mm]ake*" EXCLUDE)

add_subdirectory(html)

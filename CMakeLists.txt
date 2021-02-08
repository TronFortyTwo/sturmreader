project(sturmreader C CXX)
cmake_minimum_required(VERSION 3.2.0)

set(PROJECT_NAME sturmreader.emanuelesorce)
set(APPARMOR_FILE apparmor/sturmreader.json)
set(DESKTOP_NAME "Sturm Reader")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -fno-permissive -pedantic -Wall -Wextra -fPIC")

if(CMAKE_VERSION VERSION_LESS "3.7.0")
	set(CMAKE_INCLUDE_CURRENT_DIR ON)
endif()

# Standard install paths
include(GNUInstallDirs)
include(FindPkgConfig)

option(CLICK_MODE "Installs to a contained locaton" on)
option(FS_ACCESS "Gets filesystem access through apparmor" off)

set(DESKTOP_COMMENT "E-Book reader designed for mobile devices")

set(DESKTOP_FILE "sturmreader.desktop")
set(APP_HARDCODE sturmreader)
set(ICON_FILE "ui/sturmreader.svg")

# Check if build is out of source tree and sets boolean value
set(OUT_OF_TREE_BUILD true)
if(${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_BINARY_DIR})
    set(OUT_OF_TREE_BUILD false)
endif(${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_BINARY_DIR})

# Scan the default include directories to find packages that will be needed for building
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

find_package(Qt5Core REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Xml REQUIRED)
find_package(Qt5Svg REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5QuickControls2 REQUIRED)

find_package(ZLIB REQUIRED)
find_package(Intl REQUIRED)
find_package(QuaZip REQUIRED)

file(GLOB I18N_SRC_FILES
     RELATIVE ${CMAKE_SOURCE_DIR}
     ui/qml/*.qml )
#${DESKTOP_FILE}.tr)
# DefaultCover.qml doesn't have any translatable strings, but it does confuse xgettext.
list(REMOVE_ITEM I18N_SRC_FILES ui/qml/DefaultCover.qml)

if(CLICK_MODE)
    # Find out the architecture for package building
    # to determine the plugin's installation path
    execute_process(
        COMMAND dpkg-architecture -qDEB_HOST_ARCH
        OUTPUT_VARIABLE ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(CMAKE_INSTALL_PREFIX /)
    set(CMAKE_INSTALL_BINDIR /)
    set(DATA_DIR /)
    set(DESKTOP_DIR ${DATA_DIR})
    set(ICON ${ICON_FILE})
    set(EXEC "./sturmreader --appargs=\"%f\"")
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/manifest.json DESTINATION ${DATA_DIR})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/contenthub.json DESTINATION ${DATA_DIR})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/sturmreader.json DESTINATION ${DATA_DIR})
else(CLICK_MODE)
    set(DATA_DIR /usr/share/${PROJECT_NAME})
    set(DESKTOP_DIR /usr/share/applications)
    set(EXEC "${DATA_DIR}/sturmreader-launch")
    set(ICON ${DATA_DIR}/${ICON_FILE})
    install(PROGRAMS ${CMAKE_CURRENT_SOURCE_DIR}/sturmreader-launch DESTINATION ${DATA_DIR})
endif(CLICK_MODE)

#Copies specific individual files into the build directory
#configure_file(${DESKTOP_FILE}.tr ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}.tr)
#install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/sturmreader DESTINATION ${DATA_DIR})
configure_file(${DESKTOP_FILE}.in ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE} DESTINATION ${DESKTOP_DIR})

add_subdirectory(ui)

# compiles the main EXEC
add_executable(sturmreader
	ui/main.cpp
	ui/gettext.cpp
	ui/units.cpp
	ui/fontlister.cpp
	ui/filesystem.cpp
	ui/mimetype.cpp
	ui/stylesetting.cpp
	ui/qhttpserver/qhttpserver.cpp
	ui/qhttpserver/fileserver.cpp
	ui/qhttpserver/qhttpconnection.cpp
	ui/qhttpserver/qhttprequest.cpp
	ui/qhttpserver/qhttpresponse.cpp
	ui/qhttpserver/http-parser/http_parser.c
	ui/reader/epubreader.cpp
	ui/reader/pdfreader.cpp
	ui/resources.qrc
	${QT_RESOURCES} )
target_include_directories(sturmreader SYSTEM PRIVATE ${QUAZIP_INCLUDE_DIR})
target_link_libraries(sturmreader poppler-qt5 ${Intl_LIBRARIES} ${QUAZIP_LIBRARIES} ZLIB::ZLIB Qt5::Core Qt5::Gui Qt5::Qml Qt5::Xml Qt5::Svg Qt5::Quick Qt5::QuickControls2)
install(TARGETS sturmreader RUNTIME DESTINATION ${DATA_DIR})

# localization
add_subdirectory(po)

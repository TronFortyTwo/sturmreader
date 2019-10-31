project(sturmreader C CXX)
cmake_minimum_required(VERSION 3.0.0)

# ------------------------------------
# Set this one to on to build the + version
# ------------------------------------
option(PLUS_VERSION "Package the Plus version" off)

if(PLUS_VERSION)
	set(PROJECT_NAME sturmreader.plus.emanuelesorce)
	set(APPARMOR_FILE apparmor/sturmreader.access.json)
	set(DESKTOP_NAME "Sturm Reader +")
else(PLUS_VERSION)
	set(PROJECT_NAME sturmreader.emanuelesorce)
	set(APPARMOR_FILE apparmor/sturmreader.json)
	set(DESKTOP_NAME "Sturm Reader")
endif(PLUS_VERSION)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-permissive -pedantic -Wall -Wextra -fPIC")

# Find includes in corresponding build directories
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(UBUNTU_PROJECT_TYPE "ClickApp" CACHE INTERNAL "Tells QtCreator this is a Click application project")
set(UBUNTU_MANIFEST_PATH "manifest.json.in" CACHE INTERNAL "Tells QtCreator location and name of the manifest file")

# Standard install paths
include(GNUInstallDirs)
include(FindPkgConfig)

option(CLICK_MODE "Installs to a contained locaton" on)
option(FS_ACCESS "Gets filesystem access through apparmor" off)

set(SUFFIX "")

set(DESKTOP_FILE "sturmreader.desktop")
set(DESKTOP_COMMENT "E-Book Reader for Ubuntu Touch")
set(APP_HARDCODE sturmreader)
set(ICON_FILE sturmreader.png)
# Check if build is out of source tree and sets boolean value
set(OUT_OF_TREE_BUILD true)
if(${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR})
    set(OUT_OF_TREE_BUILD false)
endif(${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR})

# Scan the default include directories to find packages that will be needed for building plugins
find_package(Qt5Core REQUIRED Qt5Qml Qt5Quick Qt5Xml Qt5Gui Qt5Network)

file(GLOB I18N_SRC_FILES
     RELATIVE ${CMAKE_SOURCE_DIR}
     ui/*.qml )

# DefaultCover.qml doesn't have any translatable strings, but it does confuse xgettext.
list(REMOVE_ITEM I18N_SRC_FILES ui/DefaultCover.qml)

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
    set(EXEC "qmlscene -I ./ ui/main.qml --appargs=\"%f\"")
    configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${DATA_DIR})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/contenthub.json DESTINATION ${DATA_DIR})
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/apparmor DESTINATION ${DATA_DIR})
else(CLICK_MODE)
    set(DATA_DIR ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME})
    set(DESKTOP_DIR ${CMAKE_INSTALL_DATADIR}/applications)
    set(EXEC "${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/sturmreader %f")
    set(ICON ${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/${ICON_FILE})
    install(CODE "file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/sturmreader.in
        \"${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/sturmreader\")")
    install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/sturmreader.in DESTINATION ${CMAKE_INSTALL_BINDIR} RENAME sturmreader)
endif(CLICK_MODE)

#Copies specific individual files into the build directory
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/sturmreader ${CMAKE_CURRENT_BINARY_DIR}/sturmreader @ONLY)
configure_file(${DESKTOP_FILE}.in ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/sturmreader DESTINATION ${DATA_DIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE} DESTINATION ${DESKTOP_DIR})
install(FILES ${ICON_FILE} DESTINATION ${DATA_DIR})

# Add the needed subdirectories to be built and look for a CMakeLists.txt file in each directory
add_subdirectory(epubreader)
add_subdirectory(filesystem)
add_subdirectory(fontlister)
add_subdirectory(html)
add_subdirectory(qhttpserver)
add_subdirectory(ui)
add_subdirectory(po)

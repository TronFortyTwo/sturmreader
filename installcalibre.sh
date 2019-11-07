#!/bin/bash

mkdir -p "$INSTALL_DIR"/calibre/PYTHON/calibre
mkdir -p "$INSTALL_DIR"/calibre/RESOURCES
mkdir -p "$INSTALL_DIR"/calibre/PYTHON/lib-dynload/

cp -r -p /usr/lib/calibre/* "$INSTALL_DIR"/calibre/PYTHON/calibre
# Do resources really are needed? yes, at least the .py files
cp -r -p /usr/share/calibre/* "$INSTALL_DIR"/calibre/RESOURCES
cp -r -p /usr/lib/python2.7/*py "$INSTALL_DIR"/calibre/PYTHON/
cp -r -p /usr/lib/python2.7/lib-dynload/future_builtins.arm-linux-gnueabihf.so "$INSTALL_DIR"/calibre/PYTHON/lib-dynload

# we copy only the calibre commands we use
cp -r -p calibre/calibredb "$INSTALL_DIR"/calibre/

# we delete resources we don't use
find "$INSTALL_DIR"/calibre/RESOURCES -type f \( -name "*.png" -o -name ".svg" -o -name "*.jpg" -o -name "*.gif" -o -name "*.css" -o -name "*.html" -o -name "*.htm" -o -name "*.js" \) -delete
find "$INSTALL_DIR"/calibre/RESOURCES -empty -type d -delete

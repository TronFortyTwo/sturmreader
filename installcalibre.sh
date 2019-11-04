#!/bin/bash

mkdir -p "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin/
mkdir -p "$INSTALL_DIR"/calibre/PYTHON
mkdir -p "$INSTALL_DIR"/calibre/RESOURCES

cp -r -p /usr/lib/calibre/* "$INSTALL_DIR"/calibre/PYTHON
# Do resources really are needed?
#cp -r -p /usr/share/calibre/* "$INSTALL_DIR"/calibre/RESOURCES
cp -r -p /usr/bin/python2.7 "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin
cp -r -p calibre/setupcalibre "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin
cp -r -p /bin/cp "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin
cp -r -p /bin/mkdir "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin

# we copy only the calibre commands we use
cp -r -p calibre/calibredb "$INSTALL_DIR"/calibre/

# we delete resources we don't use
find "$INSTALL_DIR"/calibre/RESOURCES -type f \( -name "*.png" -o -name ".svg" -o -name "*.jpg" -o -name "*.gif" -o -name "*.css" -o -name "*.html" -o -name "*.htm" \) -delete

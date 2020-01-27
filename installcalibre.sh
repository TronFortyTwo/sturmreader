#!/bin/bash

mkdir -p "$INSTALL_DIR"/calibre/PYTHON/lib/calibre/
mkdir -p "$INSTALL_DIR"/calibre/RESOURCES
mkdir -p "$INSTALL_DIR"/calibre/PYTHON/lib/python2.7/lib-dynload/

cp -r -p /usr/lib/calibre/* "$INSTALL_DIR"/calibre/PYTHON/lib/calibre
# Do resources really are needed? yes, at least the .py files
cp -r -p /usr/share/calibre/* "$INSTALL_DIR"/calibre/RESOURCES
cp -r -p /usr/lib/python2.7/ "$INSTALL_DIR"/calibre/PYTHON/lib/

# we copy only the calibre commands we use
cp -r -p /usr/bin/calibredb "$INSTALL_DIR"/calibre/
cp -r -p /usr/bin/calibre-customize "$INSTALL_DIR"/calibre/
cp -r -p /usr/bin/ebook-convert "$INSTALL_DIR"/calibre/

# plugin we wabt to install
cp DeDRM_plugin.zip "$INSTALL_DIR"/calibre/
cp obok_plugin.zip "$INSTALL_DIR"/calibre/

# fix OSERR 13 error on pthread import
sed -i "s/libpthread_path = ctypes.util.find_library/libpthread_path = False #/g" "$INSTALL_DIR"/calibre/PYTHON/lib/calibre/calibre/startup.py

# fix encoding error when converting
# ANSI_X3.4-1968
#sed -i "s/filesystem_encoding = sys.getfilesystemencoding()/filesystem_encoding='ASCII'/g" "$INSTALL_DIR"/calibre/PYTHON/lib/calibre/calibre/constants.py

# we delete resources we don't use
# find "$INSTALL_DIR"/calibre/RESOURCES -type f \( -name "*.ico" -o -name "*.zip" -o -name "*.png" -o -name ".svg" -o -name "*.jpg" -o -name "*.gif" -o -name "*.css" -o -name "*.html" -o -name "*.htm" -o -name "*.js" \) -delete
#find "$INSTALL_DIR"/calibre/RESOURCES -empty -type d -delete

find "$INSTALL_DIR"/calibre/PYTHON -type f \( -name "*.pyc" -o -name ".pyo" \) -delete

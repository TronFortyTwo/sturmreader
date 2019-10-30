#!/bin/bash

mkdir -p "$INSTALL_DIR"/calibre/PYTHON
mkdir -p "$INSTALL_DIR"/calibre/RESOURCES
mkdir -p "$INSTALL_DIR"/calibre/EXECUTABLES

cp -r -p /usr/lib/calibre/* "$INSTALL_DIR"/calibre/PYTHON
cp -r -p /usr/share/calibre/* "$INSTALL_DIR"/calibre/RESOURCES
cp -r -p "$ROOT"/calibre/* "$INSTALL_DIR"/calibre/EXECUTABLES
cp -r -p /usr/bin/python2.7 "$INSTALL_DIR"/calibre/EXECUTABLES

find "$INSTALL_DIR"/calibre/ -name '*.png' -delete
find "$INSTALL_DIR"/calibre/ -name '*.jpg' -delete
find "$INSTALL_DIR"/calibre/ -name '*.gif' -delete

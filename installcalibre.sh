#!/bin/bash

mkdir -p "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin/
mkdir -p "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin/PYTHON
mkdir -p "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin/RESOURCES

cp -r -p /usr/lib/calibre/* "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin/PYTHON
cp -r -p /usr/share/calibre/* "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin/RESOURCES
cp -r -p /usr/bin/python2.7 "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin
cp -r -p calibre/calibredb "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin

find "$INSTALL_DIR"/lib/${ARCH_TRIPLET}/bin/RESOURCES -type f \( -name "*.png" -o -name ".svg" -o -name "*.jpg" -o -name "*.gif" \) -delete

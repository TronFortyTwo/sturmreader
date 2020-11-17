/* Copyright 2015 Robert Schroll
 * Copyright 2020 Emanuele Sorce emanuele.sorce@hotmail.com
 * 
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9

Item {
    id: reader

    signal contentsReady(var contents)

    property string fileType: ""
    property var currentReader: {
        switch (fileType) {
			case "EPUB":
				return epubreader
			case "CBZ":
				return cbzreader
			case "PDF":
				return pdfreader
			default:
				return undefined
        }
    }
    property string filename: ""
    property bool pictureBook: currentReader !== epubreader
    property string error: {
        if (currentReader === undefined)
            return gettext.tr("Could not determine file type.\n\n" +
                           "Remember, Sturm Reader can only open EPUB, PDF, and CBZ files without DRM.")
        else
            return gettext.tr("Could not parse file.\n\n" +
                           "Although it appears to be a %1 file, it could not be parsed by Sturm Reader.").arg(fileType)
    }

    Connections {
        target: epubreader
        onContentsReady: reader.contentsReady(contents)
    }

    Connections {
        target: cbzreader
        onContentsReady: reader.contentsReady(contents)
    }

    Connections {
        target: pdfreader
        onContentsReady: reader.contentsReady(contents)
    }

    function load(fn) {
		filename = fn
        fileType = filesystem.fileType(filename)
        if (currentReader === undefined)
            return false
        return currentReader.load(filename)
    }

    function hash() {
		if (currentReader !== undefined)
			return currentReader.hash
		else return undefined
    }

    function title() {
		if (currentReader !== undefined)
			return currentReader.title
		else return undefined
    }

    function serveBookData(response) {
        currentReader.serveBookData(response)
    }

    function serveComponent(filename, response) {
        currentReader.serveComponent(filename, response)
    }

    function getCoverInfo(thumbsize, fullsize) {
        return currentReader.getCoverInfo(thumbsize, fullsize)
    }
    
    Component.onCompleted: {
		pdfreader.width = mainView.width;
		pdfreader.height = mainView.height;
	}
}

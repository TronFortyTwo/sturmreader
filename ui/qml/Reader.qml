/* Copyright 2015 Robert Schroll
 * Copyright 2020 Emanuele Sorce emanuele.sorce@hotmail.com
 * 
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Item {
    id: reader

    signal contentsReady(var contents)

    property string fileType: ""
    property var currentReader: undefined
	
    property string filename: ""
	property string error: currentReader === undefined ?
		gettext.tr("Could not determine file type.") + " " + gettext.tr("Remember, Sturm Reader can only open EPUB, PDF, and CBZ files without DRM."):
		gettext.tr("Could not parse file.") + " " + gettext.tr("Although it appears to be a %1 file, it could not be parsed by Sturm Reader.").arg(fileType)

	Connections {
		target: epubreader
		onContentsReady: { reader.contentsReady(contents) }
	}
	
	Item {
		id: cbzreader
		
		property string hash: "CBZ hash"
		property string title: "CBZ title"
		function load(filename) {
			title = filename;
			hash = filename;
			return true;
		}
		function serveBookData(response) {}
		function serveComponent(filename, response) {}
		function getCoverInfo(thumbsize, fullsize) {
			return {
				filename: title,
				title: "ZZZnone",
				author: "",
				authorsort: "zzznone",
				cover: "ZZZerror",
				fullcover: ""
			};
		}
		
		signal contentsReady
	}

	Connections {
		target: pdfreader
		onContentsReady: { reader.contentsReady(contents) }
	}

    function load(fn) {
		filename = fn;
		fileType = filesystem.fileType(filename);
		
		currentReader = fileType == "EPUB" ? epubreader :
						fileType == "PDF" ? pdfreader :
						fileType == "CBZ" ? cbzreader : undefined;
		
		console.log("fileType: " + fileType);
		
		if (currentReader === undefined)
			return false;
		return currentReader.load(filename);
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

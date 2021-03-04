/* Copyright 2013-2015 Robert Schroll
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 * 
 * Copyright 2020 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9

import HttpUtils 1.0

Item {
    id: server
    
    property int port: 5000
    
    Component.onCompleted: {
        while (!httpserver.listen("127.0.0.1", port))
            port += 1
    }

    property var reader: Reader {
        id: reader
    }

    function static_file(path, response) {
        // Need to strip off leading "file://"
		//fileserver.serve(Qt.resolvedUrl(path).slice(7), response)
		
		fileserver.serve(path, response)
    }

    function defaults(response) {
        response.setHeader("Content-Type", "application/javascript")
        response.writeHead(200)

        var styles = bookPage.bookSettings.asObject()
        response.write("DEFAULT_STYLES = " + JSON.stringify(styles) + ";\n")

        var locus = getBookSetting("locus")
        if (locus == undefined)
            locus = null
        response.write("SAVED_PLACE = " + JSON.stringify(locus) + ";\n")

        response.end()
    }
    
    function received(response) {
		response.setHeader("Content-Type", "application/json");
		response.writeHead(200);
		response.write("{}");
		response.end();
	}
    
	property var partial_messages_store: ({})
    
	function manageApiCall(message, size, id) {
		if(size > 1) {
			// end of message
			if(message == "END OF SPLITTED MESSAGE") {
				manageApiCall(partial_messages_store[id], false, "");
				partial_messages_store[id] = undefined;
			}
			// new part of message
			else {
				if(!partial_messages_store[id])
					partial_messages_store[id] = message;
				else
					partial_messages_store[id] = partial_messages_store[id] + message;
			}
		} else {
			if(mainView.bookPage)
				mainView.bookPage.parseApiCall(message);
		}
	}
    
	Connections {
		target: httpserver
		
		onNewRequest: {
			// new pdf reader
			if (request.path == "/PDF") {
// 				if(appsettings.legacypdf)
// 					return static_file("../html/monocle.html", response)
// 				else
					return static_file(":/html/pdfjs.html", response)
			}
			// the monocle reader
			else if (request.path == "/EPUB")
				return static_file(":/html/monocle.html", response)
			else if (request.path == "/CBZ") {
				openConverter(reader.filename);
				return received(response);
			}
			// the pdf document
			else if (request.path == "/book.pdf")
				return static_file(reader.filename, response)
			else if (request.path == "/.bookdata.js")
				return reader.serveBookData(response)
			else if (request.path == "/.defaults.js")
				return defaults(response)
			else if (request.path == "/API" ) {
				manageApiCall(decodeURI(request.header("message")), request.header("size"), decodeURI(request.header("id")));
				return received(response);
			}
			else if (request.path[0] == "/" && request.path[1] == ".")
				return static_file(":/html/" + request.path.slice(2), response)
			return reader.serveComponent(request.path.slice(1), response)
		}
	}
}

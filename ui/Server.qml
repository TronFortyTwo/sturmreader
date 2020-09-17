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
import HttpServer 1.0

HttpServer {
    id: server
    
    property int port: 5000
    
    Component.onCompleted: {
        while (!listen("127.0.0.1", port))
            port += 1
    }

    property var reader: Reader {
        id: reader
    }

    property var fileserver: FileServer {
        id: fileserver
    }

    function static_file(path, response) {
        // Need to strip off leading "file://"
        fileserver.serve(Qt.resolvedUrl(path).slice(7), response)
    }

    function defaults(response) {
        response.setHeader("Content-Type", "application/javascript")
        response.writeHead(200)

        var styles = bookPage.getBookStyles()
        response.write("DEFAULT_STYLES = " + JSON.stringify(styles) + ";\n")

        var locus = getBookSetting("locus")
        if (locus == undefined)
            locus = null
        response.write("SAVED_PLACE = " + JSON.stringify(locus) + ";\n")

        response.end()
    }
    
    onNewRequest: { // request, response
		// new pdf reader
		if (request.path == "/PDF")
			return static_file("../html/pdf.html", response)
        // the monocle reader
		if (request.path == "/EPUB")
            return static_file("../html/monocle.html", response)
		// TODO: CBZ is more pdf than epub
		if (request.path == "/CBZ")
            return static_file("../html/monocle.html", response)
		
		if (request.path == "/book.pdf")
			return static_file(reader.filename, response)
			
        if (request.path == "/.bookdata.js")
            return reader.serveBookData(response)
        if (request.path == "/.defaults.js")
            return defaults(response)
        if (request.path[1] == ".")
            return static_file("../html/" + request.path.slice(2), response)
        return reader.serveComponent(request.path.slice(1), response)
    }
}

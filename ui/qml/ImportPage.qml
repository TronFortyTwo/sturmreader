 /* Copyright 2020 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
 
Page {
	
	id: importPage
	
	property var bookList: itemList
	property var reader: importReader
	
    property var importState: { "new": 1, "processing": 2, "imported": 3, "exists": 4, "error": 5 }
    property bool importing: false
	
	ListModel {
        id: itemList
    }
    
    Reader {
        id: importReader
    }
	
	header: ToolBar {
		width: parent.width
		RowLayout {
			spacing: scaling.dp(10)
			anchors.fill: parent
			
			BusyIndicator {
				visible: importing
				height: parent.height * 0.9
				width: height
			}
			
			Label {
				text: importing ? gettext.tr("Importing books...") : gettext.tr("Books imported")
				font.pixelSize: headerTextSize()
				elide: Label.ElideRight
				horizontalAlignment: Qt.AlignLeft
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
			
			ToolButton {
				visible: !importing
				padding: scaling.dp(7)
				contentItem: Icon {
					anchors.centerIn: parent
					name: "ok"
					color: colors.item
				}
				onClicked: {
					if (!importing) {
						itemList.clear()
						pageStack.pop()
					}
				}
			}
		}
	}
	
	ListView {
		id: sourcesView
		anchors.fill: parent

		model: itemList
		delegate: SuperDelegate {
			width: sourcesView.width
			
			main_text: model.item.url.toString().split("/").pop()
			sub_text: {
				switch (model.state) {
					case importState.new:
						return gettext.tr("Waiting")
					case importState.processing:
						return gettext.tr("Processing")
					case importState.imported:
						return gettext.tr("Imported to %1").arg(model.importName)
					case importState.exists:
						return gettext.tr("Already in library: %1").arg(model.importName)
					case importState.error:
						return gettext.tr("Error: %1").arg(model.error.split("\n\n")[0])
				}
			}
			onClicked: {
				if (!importing)
					clearAndLoad(model)
			}
		}
		ScrollBar.vertical: ScrollBar { }
	}
	
	Timer {
        id: importTimer
        interval: 10
        onTriggered: {
            for (var i=0; i<importPage.bookList.count; i++) {
                var book = importPage.bookList.get(i)
                if (book.state == importState.new) {
					// remove 'file://' from the filename
					var filename = book.item.url.toString().slice(7)
                    if (importPage.reader.load(filename)) {
                        localBooks.inDatabase(
                                    importPage.reader.hash(),
                                    (function (book) {
                                        return function (currentfilename) {
                                            book.importName = currentfilename
                                            book.state = importState.exists
                                        }
                                    })(book),
                                    doImport(filename, book))
                    } else {
                        book.state = importState.error
                        book.error = importPage.reader.error
                    }
                    break
                }
            }
            if (i == importPage.bookList.count) {
                importing = false
                if (importPage.bookList.count == 1)
                    clearAndLoad(importPage.bookList.get(0))
            } else {
                importTimer.start()
            }
        }
    }
	
	function importItems(items) {
        pageStack.push(importPage)
        importing = true
        for (var i=0; i<items.length; i++) {
            importPage.bookList.append({ "item": items[i], "state": importState.new, "error": "", "importName": "" })
        }
        importTimer.start()
    }

    function clearAndLoad(item) {
        if (item.importName != "") {
            var name = item.importName
            importPage.bookList.clear()
            loadFile(name)
        }
    }
	
	function doImport(filename, book) {
        return function () {
            var components = filename.split("/").pop().split(".")
            var ext = components.pop()
            var dir = filesystem.getDataDir(localBooks.defaultdirname)
            var basename = components.join(".")
            var newfilename = basename + "." + ext
            var i = 0
            while (filesystem.exists(dir + "/" + newfilename)) {
                i += 1
                newfilename = basename + "(" + i + ")." + ext
            }
            
			book.importName = dir + "/" + newfilename;
            
            if(typeof book.item.move !== 'undefined')
				var copy_success = book.item.move(dir, newfilename)
            else
				var copy_success = filesystem.copy(book.item.url.toString().slice(7), book.importName);
			
			// copy failed
			if(!copy_success) {
				console.log("importing file '" + book.item.url + "' failed");
				book.state = importState.error;
				return;
			}
			
			// DON'T Convert right now, but let the conversion been made at first opening
			// if it's a CBZ, convert to a pdf
			//if(ext.toLowerCase() == "cbz") {
				//var new_newfilename = dir + "/" + basename + "(" + i + ").pdf";
				//if(!filesystem.convertCbz2Pdf(book.importName, new_newfilename)){
					//console.log("error converting");
					//book.state = importState.error;
					//return;
				//}
				//book.importName = new_newfilename;
			//}
			
			book.item.url = book.importName;
			localBooks.addFile(book.importName, true);
			book.state = importState.imported;
        }
    }
}

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
			
			Label {
				text: gettext.tr("Importing books...")
				font.pixelSize: scaling.dp(22)
				elide: Label.ElideRight
				horizontalAlignment: Qt.AlignLeft
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
			
			ToolButton {
				padding: scaling.dp(7)
				contentItem: Icon {
					anchors.centerIn: parent
					name: importing ? "refresh" : "ok"
					color: Theme.palette.normal.baseText
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
		delegate: ItemDelegate {
			width: parent.width
			contentItem: Item {
				implicitWidth: parent.width
				implicitHeight: scaling.dp(42)
				Column {
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					spacing: scaling.dp(5)
					Text {
						text: model.item.url.toString().split("/").pop()
						color: theme.palette.normal.backgroundText
						font.pointSize: scaling.dp(12)
					}
					Text {
						text: {
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
						color: theme.palette.normal.backgroundText
						font.pointSize: scaling.dp(9)
					}
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
                var item = importPage.bookList.get(i)
                if (item.state == importState.new) {
                    var filename = item.item.url.toString().slice(7)
                    if (importPage.reader.load(filename)) {
                        localBooks.inDatabase(
                                    importPage.reader.hash(),
                                    (function (item) {
                                        return function (currentfilename) {
                                            item.importName = currentfilename
                                            item.state = importState.exists
                                        }
                                    })(item),
                                    doImport(filename, item))
                    } else {
                        item.state = importState.error
                        item.error = importPage.reader.error
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
	
	function doImport(filename, item) {
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
            item.item.move(dir, newfilename)
            item.importName = dir + "/" + newfilename
            localBooks.addFile(item.importName, true)
            item.state = importState.imported
        }
    }
}

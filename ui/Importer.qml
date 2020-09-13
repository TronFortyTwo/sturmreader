/* Copyright 2015 Robert Schroll
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Ubuntu.Content 1.3 as UUITK

import "components"
import "not-portable"

//import "components"

Item {
    id: importer
    property var activeTransfer: null
    property var pickerPage: picker
    property var importState: { "new": 1, "processing": 2, "imported": 3, "exists": 4, "error": 5 }
    property bool importing: false

    Connections {
        target: UUITK.ContentHub
        onImportRequested: {
            activeTransfer = transfer
            if (activeTransfer.state === UUITK.ContentTransfer.Charged)
                importItems(activeTransfer.items)
        }
    }

    Connections {
        target: activeTransfer
        onStateChanged: {
            if (activeTransfer.state === UUITK.ContentTransfer.Charged)
                importItems(activeTransfer.items)
        }
    }

    Reader {
        id: importReader
    }

    function doImport(filename, item) {
        return function () {
            var components = filename.split("/").pop().split(".")
            var ext = components.pop()
            var dir = filesystem.getDataDir(localBooks.defaultdirname)
            var basename =components.join(".")
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

    function importItems(items) {
        pageStack.push(importPage)
        importing = true
        for (var i=0; i<items.length; i++) {
            itemList.append({ "item": items[i], "state": importState.new, "error": "", "importName": "" })
        }
        importTimer.start()
    }

    function clearAndLoad(item) {
        if (item.importName != "") {
            var name = item.importName
            itemList.clear()
            loadFile(name)
        }
    }

    Timer {
        id: importTimer
        interval: 10
        onTriggered: {
            for (var i=0; i<itemList.count; i++) {
                var item = itemList.get(i)
                if (item.state == importState.new) {
                    var filename = item.item.url.toString().slice(7)
                    if (importReader.load(filename)) {
                        localBooks.inDatabase(
                                    importReader.hash(),
                                    (function (item) {
                                        return function (currentfilename) {
                                            item.importName = currentfilename
                                            item.state = importState.exists
                                        }
                                    })(item),
                                    doImport(filename, item))
                    } else {
                        item.state = importState.error
                        item.error = importReader.error
                    }
                    break
                }
            }
            if (i == itemList.count) {
                importing = false
                if (itemList.count == 1)
                    clearAndLoad(itemList.get(0))
            } else {
                importTimer.start()
            }
        }
    }

    ListModel {
        id: itemList
    }

    Page {
        id: importPage
        visible: false
        
		header: ToolBar {
			width: parent.width
			RowLayout {
				spacing: units.dp(2)
				anchors.fill: parent
				
				ToolButton {
					padding: units.dp(7)
					contentItem: Icon {
						anchors.centerIn: parent
						name: importing ? "refresh" : "go-previous"
						color: Theme.palette.normal.baseText
					}
					onClicked: {
						if (!importing) {
							itemList.clear()
							pageStack.pop()
						}
					}
				}
				
				Label {
					text: i18n.tr("Importing books...")
					font.pixelSize: units.dp(22)
					elide: Label.ElideRight
					horizontalAlignment: Qt.AlignLeft
					verticalAlignment: Qt.AlignVCenter
					Layout.fillWidth: true
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
					implicitHeight: units.dp(42)
					Column {
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.verticalCenter: parent.verticalCenter
						spacing: units.dp(5)
						Text {
							text: model.item.url.toString().split("/").pop()
							color: theme.palette.normal.backgroundText
							font.pointSize: units.dp(12)
						}
						Text {
							text: {
								switch (model.state) {
									case importState.new:
										return i18n.tr("Waiting")
									case importState.processing:
										return i18n.tr("Processing")
									case importState.imported:
										return i18n.tr("Imported to %1").arg(model.importName)
									case importState.exists:
										return i18n.tr("Already in library: %1").arg(model.importName)
									case importState.error:
										return i18n.tr("Error: %1").arg(model.error.split("\n\n")[0])
								}
							}
							color: theme.palette.normal.backgroundText
							font.pointSize: units.dp(9)
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
    }

    Page {
        id: picker
        visible: false
        UUITK.ContentPeerPicker {
            handler: UUITK.ContentHandler.Source
            contentType: UUITK.ContentType.Documents
            headerText: i18n.tr("Import books from")

            onPeerSelected: {
                peer.selectionType = UUITK.ContentTransfer.Multiple
                activeTransfer = peer.request()
                pageStack.pop()
            }

            onCancelPressed: pageStack.pop()
        }
    }

	UUITK.ContentTransferHint {
        activeTransfer: importer.activeTransfer
    }
}

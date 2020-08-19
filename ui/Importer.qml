/* Copyright 2015 Robert Schroll
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3 as UUITK
import Ubuntu.Components.Popups 1.3 as UUITK
import Ubuntu.Components.ListItems 1.3 as UUITK
import Ubuntu.Content 1.3 as UUITK

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

    UUITK.Page {
        id: importPage
        visible: false
        header: UUITK.PageHeader {
			id: importpageheader
			title: i18n.tr("Importing books...")
			leadingActionBar.actions: [
				UUITK.Action {
					iconName: importing ? "preferences-system-updates-symbolic" : "back"
					onTriggered: {
						if (!importing) {
							itemList.clear()
							pageStack.pop()
						}
					}
				}
			]
        }

        ListView {
            id: sourcesView
            anchors.top: importpageheader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            model: itemList
            delegate: UUITK.Subtitled {
                text: model.item.url.toString().split("/").pop()
                subText: {
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
                onClicked: {
                    if (!importing)
                        clearAndLoad(model)
                }
            }
        }
        UUITK.Scrollbar {
            flickableItem: sourcesView
            align: Qt.AlignTrailing
        }
    }

    UUITK.Page {

        header: UUITK.PageHeader {
            visible: false
        }

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

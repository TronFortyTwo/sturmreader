/* Copyright 2015 Robert Schroll
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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Ubuntu.Content 1.3 as UUITK
import Ubuntu.Components 1.3 as UUITK

Item {
    id: importer
    property var activeTransfer: null
    property var pickerPage: picker

    Connections {
        target: UUITK.ContentHub
        onImportRequested: {
            activeTransfer = transfer
            if (activeTransfer.state === UUITK.ContentTransfer.Charged)
                importPage.importItems(activeTransfer.items)
        }
    }

    Connections {
        target: activeTransfer
        onStateChanged: {
            if (activeTransfer.state === UUITK.ContentTransfer.Charged)
                importPage.importItems(activeTransfer.items)
        }
    }
    
    ImportPage {
		id: importPage
		visible: false
	}

    UUITK.Page {
        id: picker
        visible: false
        UUITK.ContentPeerPicker {
            handler: UUITK.ContentHandler.Source
            contentType: UUITK.ContentType.Documents
            headerText: gettext.tr("Import books from")

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

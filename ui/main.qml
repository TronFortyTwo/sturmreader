/* Copyright 2013-2015 Robert Schroll
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 *
 * Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GNU GPLv3. See the file COPYING for full details.
 */

import Ubuntu.Components 1.3

import QtQuick 2.9
import QtQuick.LocalStorage 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Qt.labs.settings 1.0
import File 1.0

import Units 1.0

import "components"
import "not-portable"

ApplicationWindow {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"
    id: mainView
    title: defaultTitle
    visible: true
    
    property string defaultTitle: "Sturm Reader"
	property var bookPageComponent: Qt.createComponent("BookPage.qml")
	property var bookPage: null
    
    width: units.dp(800)
    height: units.dp(600)

    FileSystem {
        id: filesystem
    }

    StackView {
        id: pageStack
		anchors.fill: parent
        initialItem: localBooks
    }
	
	LocalBooks {
		id: localBooks
		visible: false
	}

    Dialog {
		id: errorOpenDialog
		title: i18n.tr("Error Opening File")
		modal: true
		visible: false
		x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
		Label {
			text: server.reader.error
		}
		standardButtons: Dialog.Ok
	}

    Server {
        id: server
    }

    Importer {
        id: importer
    }

    function loadFile(filename) {
        if (server.reader.load(filename)) {
            while (pageStack.currentItem != localBooks)
                pageStack.pop()
			// create bookPage
			bookPage = bookPageComponent.createObject(mainView, {url: "http://127.0.0.1:" + server.port + "/" + server.reader.fileType, visible: false});
			
            pageStack.push(bookPage)
            mainView.title = server.reader.title()
            localBooks.updateRead(filename)
			bookPage.turnControlsOn()
            return true
        }
        errorOpenDialog.open()
        return false
    }

	function openSettingsDatabase() {
		return LocalStorage.openDatabaseSync("BeruSettings", "1", "Global settings for Beru", 100000)
	}

    function getSetting(key) {
        var db = openSettingsDatabase()
        var retval = null
        db.readTransaction(function (tx) {
            var res = tx.executeSql("SELECT value FROM Settings WHERE key=?", [key])
            if (res.rows.length > 0)
                retval = res.rows.item(0).value
        })
        return retval
    }

    function setSetting(key, value) {
        var db = openSettingsDatabase()
        db.transaction(function (tx) {
            tx.executeSql("INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)", [key, value])
        })
    }

	Settings {
		id: appsettings
		category: "appsettings"
		property alias x: mainView.x
		property alias y: mainView.y
		property alias width: mainView.width
		property alias height: mainView.height
		property alias sort: localBooks.sort
		property alias legacy_pdf: server.legacy_pdf
	}

    function getBookSetting(key) {
        if (server.reader.hash() == "")
            return undefined

		var settings = JSON.parse(mainView.getSetting("book_" + server.reader.hash()))
        if (settings == undefined)
            return undefined
        return settings[key]
    }

    function setBookSetting(key, value) {
        if (server.reader.hash() == "")
            return false

        if (databaseTimer.hash != null &&
                (databaseTimer.hash != server.reader.hash() || databaseTimer.key != key))
            databaseTimer.triggered()

        databaseTimer.stop()
        databaseTimer.hash = server.reader.hash()
        databaseTimer.key = key
        databaseTimer.value = value
        databaseTimer.start()

        return true
    }

    Timer {
        id: databaseTimer
        interval: 1000
        repeat: false
        running: false
        triggeredOnStart: false
        property var hash: null
        property var key
        property var value
        onTriggered: {
            if (hash == null)
                return

            var settings = JSON.parse(getSetting("book_" + server.reader.hash()))
            if (settings == undefined)
                settings = {}
            settings[key] = value
            setSetting("book_" + server.reader.hash(), JSON.stringify(settings))
            hash = null
        }
    }

    Component.onCompleted: {
		
		var db = openSettingsDatabase()
		db.transaction(function (tx) {
			tx.executeSql("CREATE TABLE IF NOT EXISTS Settings(key TEXT UNIQUE, value TEXT)")
		})
		
		// TODO: support for importing using args
		var bookarg = undefined //Qt.application.arguments[1]
		if (bookarg != undefined && bookarg != "" && bookarg != null)
		{
			var filePath = filesystem.canonicalFilePath(bookarg)
			if (filePath !== "") {
				if (loadFile(filePath))
					localBooks.addFile(filePath)
			}
		}
        
		/*
        onWidthChanged.connect(sizeChanged)
        onHeightChanged.connect(sizeChanged)
        var size = JSON.parse(getSetting("winsize"))
        if (size != null) {
            width = size[0]
            height = size[1]
        }*/
		i18n.domain = Qt.application.name;
		
        localBooks.onMainCompleted()
    }
}

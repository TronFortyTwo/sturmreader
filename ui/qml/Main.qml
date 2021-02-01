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
import QtQuick 2.9
import QtQuick.LocalStorage 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import QtQuick.Controls.Material 2.2

import Importer 1.0

ApplicationWindow {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"
    id: mainView
    title: defaultTitle
    visible: true
    
    property string defaultTitle: "Sturm Reader"
	property var bookPageComponent: {
		var bp = Qt.createComponent("BookPage.qml");
		
		if (bp.status == Component.Error)
			console.log("Error loading component BookPage.qml:", bp.errorString());
		return bp;
	}
	property var bookPage: null
    
	// UTILS
	function headerTextSize() {
		return scaling.dp(19);
	}
	
	
	// portable palette and default material theme colors
	Material.theme: Material.Dark
	Material.primary: Material.Red
	Material.accent: Material.DeepOrange
	Colors { id: colors }
	
	// for dp scaling support
	Scaling { id: scaling }
	
	// Our own setting store since QSettings is unreliable
	onWidthChanged: { setSetting( "appconfig_width", width)}
	onHeightChanged: { setSetting( "appconfig_height", height)}
	onXChanged: { setSetting("appconfig_x", x)}
	onYChanged: { setSetting("appconfig_y", y)}
	QtObject {
		id: appsettings
		
		property alias sort: localBooks.sort
		onSortChanged: { setSetting( "appconfig_sort", appsettings.sort ); }
		
		//property bool legacypdf
		//onLegacypdfChanged: { setSetting( "appconfig_legacypdf2", appsettings.legacypdf ); }
		
		Component.onCompleted: {
			var csort = getSetting("appconfig_sort");
			var clegacypdf = getSetting("appconfig_legacypdf2");
			var cwidth = getSetting("appconfig_width");
			var cheight = getSetting("appconfig_height");
			var cx = getSetting("appconfig_x");
			var cy = getSetting("appconfig_y");
			
			if(csort) appsettings.sort = csort;
// 			if(clegacypdf) {
// 				clegacypdf = clegacypdf == "true" ? true : false;
// 				appsettings.legacypdf = clegacypdf;
// 			}
// 			// by default, use the new viewer
// 			else appsettings.legacypdf = false;
			
			if(cwidth)
				mainView.width = cwidth;
			else
				mainView.width = 800;
			
			if(cheight)
				mainView.height = cheight;
			else
				mainView.height = 600;
			
			if(cx) mainView.x = cx;
			if(cy) mainView.y = cy;
		}
		
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

	// Error
    Dialog {
		id: errorOpenDialog
		title: gettext.tr("Error Opening File")
		modal: true
		visible: false
		x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
		width: scaling.dp(300)
		height: scaling.dp(300)
		Label {
			width: scaling.dp(300)
			height: scaling.dp(300)
			text: server.reader.error
		}
		standardButtons: Dialog.Ok
	}

	// This dialog appears when we have to convert a file in our library
	Dialog {
		id: convertDialog
		visible: false	
		x: 0
        y: 0
		width: parent.width
		height: parent.height
		
		modal: true
		
		header: ToolBar {
			width: parent.width
			height: titleLabel.height + scaling.dp(10)
			Label {
				id: titleLabel
				width: parent.width
				anchors.verticalCenter: parent.verticalCenter
				text: "Conversion required"
				font.pixelSize: headerTextSize()
				wrapMode: Text.Wrap
				horizontalAlignment: Qt.AlignHCenter
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
			}
		}
		
		Column {
			width: parent.width
			Label {
				width: parent.width * 0.8
				anchors.horizontalCenter: parent.horizontalCenter
				text: gettext.tr("The file that you tried to open needs to be converted to a format supported by Sturm Reader to be opened.") +
					gettext.tr("This process is automatic and the book will be then available in your library.") + '\n' +
					gettext.tr("Press the button to start the process");
				wrapMode: Text.Wrap
			}
			
			BusyIndicator {
				id: converting_indicator
				width: scaling.dp(50)
				height: scaling.dp(50)
				anchors.horizontalCenter: parent.horizontalCenter
				running: false
			}
			
			Button {
				/* As in convert ebook format (e.g. CBZ to PDF) */
				text: gettext.tr("Convert")
				width: parent.width * 0.5
				anchors.horizontalCenter: parent.horizontalCenter
				onClicked: {
					converting_indicator.running = true;
					
					//filesystem.convertCbz2Pdf(book.importName, new_newfilename);
					//localBooks.addFile(book.importName, true);
				}
			}
		}
	}
	
    Server {
        id: server
    }

	Importer {
		id: importer
		importPage: import_page
	}
	
	ImportPage {
		id: import_page
		visible: false
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
		
		var settings = JSON.parse(getSetting("book_" + server.reader.hash()));
		
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
		
        localBooks.onMainCompleted();
    }
}

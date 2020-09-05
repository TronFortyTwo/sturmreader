/* Copyright 2013-2015 Robert Schroll
 * Copyright 2018-2020 Emanuele Sorce
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.0
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.3

import "components"

import Units 1.0


Page {
    id: localBooks

    property alias sort: footertabs.currentIndex
    property bool needsort: false
    property bool firststart: false
    property bool wide: false
    property string bookdir: ""
    property bool readablehome: false
    property string defaultdirname: i18n.tr("Books")
    property double gridmargin: units.dp(10)
    property double mingridwidth: units.dp(150)
    property bool reloading: false

    background: Rectangle {
		color: Theme.palette.normal.background
	}
    
    header: ToolBar {
		width: parent.width
		RowLayout {
			spacing: units.dp(10)
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			width: parent.width - units.dp(10)
			
			Label {
				text: i18n.tr("Library")
				font.pixelSize: units.dp(22)
				elide: Label.ElideRight
				horizontalAlignment: Qt.AlignLeft
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
			}
			
			ToolButton {
				contentItem: Icon {
					height: parent.height * 0.3
					anchors.centerIn: parent
					name: "add"
					color: Theme.palette.normal.baseText
				}
				onClicked: pageStack.push(importer.pickerPage)
			}
			
			ToolButton {
				contentItem: Icon {
					height: parent.height * 0.3
					anchors.centerIn: parent
					name: "info"
					color: Theme.palette.normal.baseText
				}
				onClicked: pageStack.push(about)
			}
			
			ToolButton {
				contentItem: Icon {
					height: parent.height * 0.3
					anchors.centerIn: parent
					name: "settings"
					color: Theme.palette.normal.baseText
				}
				onClicked: {
					if (localBooks.readablehome)
						settingsDialog.open()
					else
						settingsDisabledDialog.open()
				}
			}
		}
	}
    
	footer:	TabBar {
		id: footertabs
		width: parent.width
		TabButton {
			text: i18n.tr("Recently Read")
		}
		TabButton {
			text: i18n.tr("Title")
		}
		TabButton {
			text: i18n.tr("Author")
		}
	}
    
    onSortChanged: {
        listBooks()
        perAuthorModel.clear()
        adjustViews(false)
    }
    onWidthChanged: {
        wide = (width > units.dp(800))
        widthAnimation.enabled = false
        adjustViews(true)  // True to allow author's list if necessary
        widthAnimation.enabled = true
    }
    
    function onFirstStart(db) {
        db.changeVersion(db.version, "1")
        noBooksLabel.text = i18n.tr("Welcome to Sturm Reader!")
        firststart = true
    }

    function openDatabase() {
        return LocalStorage.openDatabaseSync("BeruLocalBooks", "", "Books on the local device",
                                             1000000, onFirstStart);
    }
    
    function fileToTitle(filename) {
        return filename.replace(/\.\w+$/, "").replace(/_/g, " ")
    }
    
    // New items are given a lastread time of now, since these are probably
    // interesting for a user to see.
    property string addFileSQL: "INSERT OR IGNORE INTO LocalBooks(filename, title, author, authorsort, " +
                                "cover, lastread) VALUES(?, ?, '', 'zzznull', 'ZZZnone', datetime('now'))"

    function addFile(filePath, startCoverTimer) {
        var fileName = filePath.split("/").pop()
        var db = openDatabase()
        db.transaction(function (tx) {
            tx.executeSql(addFileSQL, [filePath, fileToTitle(fileName)])
        })
        localBooks.needsort = true
        if (startCoverTimer)
            coverTimer.start()
    }

    function addBookDir() {
        var db = openDatabase()
        db.transaction(function (tx) {
            var files = filesystem.listDir(bookdir, ["*.epub", "*.cbz", "*.pdf"])
            for (var i=0; i<files.length; i++) {
                var fileName = files[i].split("/").pop()
                tx.executeSql(addFileSQL, [files[i], fileToTitle(fileName)])
            }
        })
        localBooks.needsort = true
    }
    
    function listBooks() {
        // We only need to GROUP BY in the author sort, but this lets us use the same
        // SQL logic for all three cases.
        var sort = ["GROUP BY filename ORDER BY lastread DESC, title ASC",
                    "GROUP BY filename ORDER BY title ASC",
                    "GROUP BY authorsort ORDER BY authorsort ASC"][localBooks.sort]
        if (sort === undefined) {
            console.log("Error: Undefined sorting: " + localBooks.sort)
            return
        }

        listview.delegate = (localBooks.sort == 2) ? authorDelegate : titleDelegate

        bookModel.clear()
        var db = openDatabase()
        db.readTransaction(function (tx) {
            var res = tx.executeSql("SELECT filename, title, author, cover, fullcover, authorsort, count(*) " +
                                    "FROM LocalBooks " + sort)
            for (var i=0; i<res.rows.length; i++) {
                var item = res.rows.item(i)
                if (filesystem.exists(item.filename))
                    bookModel.append({filename: item.filename, title: item.title,
                                      author: item.author, cover: item.cover, fullcover: item.fullcover,
                                      authorsort: item.authorsort, count: item["count(*)"]})
            }
        })
        localBooks.needsort = false
    }

    function listAuthorBooks(authorsort) {
        perAuthorModel.clear()
        var db = openDatabase()
        db.readTransaction(function (tx) {
            var res = tx.executeSql("SELECT filename, title, author, cover, fullcover FROM LocalBooks " +
                                    "WHERE authorsort=? ORDER BY title ASC", [authorsort])
            for (var i=0; i<res.rows.length; i++) {
                var item = res.rows.item(i)
                if (filesystem.exists(item.filename))
                    perAuthorModel.append({filename: item.filename, title: item.title,
                                           author: item.author, cover: item.cover, fullcover: item.fullcover})
            }
            perAuthorModel.append({filename: "ZZZback", title: i18n.tr("Back"),
                                   author: "", cover: ""})
        })
    }

    function updateRead(filename) {
        var db = openDatabase()
        db.transaction(function (tx) {
            tx.executeSql("UPDATE OR IGNORE LocalBooks SET lastread=datetime('now') WHERE filename=?",
                          [filename])
        })
        if (localBooks.sort == 0)
            listBooks()
    }

    function updateBookCover() {
        var db = openDatabase()
        db.transaction(function (tx) {
            var res = tx.executeSql("SELECT filename, title FROM LocalBooks WHERE authorsort == 'zzznull'")
            if (res.rows.length == 0)
                return

            localBooks.needsort = true
            var title, author, authorsort, cover, fullcover, hash
            if (coverReader.load(res.rows.item(0).filename)) {
                var coverinfo = coverReader.getCoverInfo(units.dp(40), 2*mingridwidth)
                title = coverinfo.title
                if (title == "ZZZnone")
                    title = res.rows.item(0).title

                author = coverinfo.author.trim()
                authorsort = coverinfo.authorsort.trim()
                if (authorsort == "zzznone" && author != "") {
                    // No sort information, so let's do our best to fix it:
                    authorsort = author
                    var lc = author.lastIndexOf(",")
                    if (lc == -1) {
                        // If no commas, assume "First Last"
                        var ls = author.lastIndexOf(" ")
                        if (ls > -1) {
                            authorsort = author.slice(ls + 1) + ", " + author.slice(0, ls)
                            authorsort = authorsort.trim()
                        }
                    } else if (author.indexOf(",") == lc) {
                        // If there is exactly one comma in the author, assume "Last, First".
                        // Thus, authorsort is correct and we have to fix author.
                        author = author.slice(lc + 1).trim() + " " + author.slice(0, lc).trim()
                    }
                }

                cover = coverinfo.cover
                fullcover = coverinfo.fullcover
                hash = coverReader.hash()
            } else {
                title = res.rows.item(0).title
                author = i18n.tr("Could not open this book.")
                authorsort = "zzzzerror"
                cover = "ZZZerror"
                fullcover = ""
                hash = ""
            }
            tx.executeSql("UPDATE LocalBooks SET title=?, author=?, authorsort=?, cover=?, " +
                          "fullcover=?, hash=? WHERE filename=?",
                          [title, author, authorsort, cover, fullcover, hash, res.rows.item(0).filename])

            if (localBooks.visible) {
                for (var i=0; i<bookModel.count; i++) {
                    var book = bookModel.get(i)
                    if (book.filename == res.rows.item(0).filename) {
                        book.title = title
                        book.author = author
                        book.cover = cover
                        book.fullcover = fullcover
                        break
                    }
                }
            }

            coverTimer.start()
        })
    }

    function refreshCover(filename) {
        var db = openDatabase()
        db.transaction(function (tx) {
            tx.executeSql("UPDATE LocalBooks SET authorsort='zzznull' WHERE filename=?", [filename])
        })

        coverTimer.start()
    }

    function inDatabase(hash, existsCallback, newCallback) {
        var db = openDatabase()
        db.readTransaction(function (tx) {
            var res = tx.executeSql("SELECT filename FROM LocalBooks WHERE hash == ?", [hash])
            if (res.rows.length > 0 && filesystem.exists(res.rows.item(0).filename))
                existsCallback(res.rows.item(0).filename)
            else
                newCallback()
        })
    }

    function readBookDir() {
        reloading = true
        addBookDir()
        listBooks()
        coverTimer.start()
        reloading = false
    }

    function adjustViews(showAuthor) {
        if (sort != 2 || perAuthorModel.count == 0)
            showAuthor = false  // Don't need to show authors' list

        if (sort == 0) {
            listview.visible = false
            gridview.visible = true
        } else {
            listview.visible = true
            gridview.visible = false
            if (!wide || sort != 2) {
                listview.width = localBooks.width
                listview.x = showAuthor ? -localBooks.width : 0
            } else {
                listview.width = localBooks.width / 2
                listview.x = 0
                listview.topMargin = 0
                perAuthorListView.topMargin = 0
            }
        }
    }

    function loadBookDir() {
        if (filesystem.readableHome()) {
            readablehome = true
            var storeddir = getSetting("bookdir")
            bookdir = (storeddir == null) ? filesystem.getDataDir(defaultdirname) : storeddir
        } else {
            readablehome = false
            bookdir = filesystem.getDataDir(defaultdirname)
        }
    }	

    function setBookDir(dir) {
        bookdir = dir
        setSetting("bookdir", dir)
    }

    Component.onCompleted: {
        var db = openDatabase()
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS LocalBooks(filename TEXT UNIQUE, " +
                          "title TEXT, author TEXT, cover BLOB, lastread TEXT)")
        })
        // NOTE: db.version is not updated live!  We will get the change only the next time
        // we run, so here we must keep track of what's been happening.  onFirstStart() has
        // already run, so we're at version 1, even if db.version is empty.
        if (db.version == "" || db.version == "1") {
            db.changeVersion(db.version, "2", function (tx) {
                tx.executeSql("ALTER TABLE LocalBooks ADD authorsort TEXT NOT NULL DEFAULT 'zzznull'")
            })
        }
        if (db.version == "" || db.version == "1" || db.version == "2") {
            db.changeVersion(db.version, "3", function (tx) {
                tx.executeSql("ALTER TABLE LocalBooks ADD fullcover BLOB DEFAULT ''")
                // Trigger re-rendering of covers.
                tx.executeSql("UPDATE LocalBooks SET authorsort='zzznull'")
            })
        }
        if (db.version == "" || db.version == "1" || db.version == "2" || db.version == "3") {
            db.changeVersion(db.version, "4", function (tx) {
                tx.executeSql("ALTER TABLE LocalBooks ADD hash TEXT DEFAULT ''")
                // Trigger re-evaluation to update hashes.
                tx.executeSql("UPDATE LocalBooks SET authorsort='zzznull'")
            })
        }
        // refresh
        readBookDir()
    }

    // We need to wait for main to be finished, so that the settings are available.
    function onMainCompleted() {
        // readBookDir() will trigger the loading of all files in the default directory
        // into the library.
        if (!firststart) {
            loadBookDir()
            readBookDir()
        } else {
            readablehome = filesystem.readableHome()
            if (readablehome) {
                setBookDir(filesystem.homePath() + "/" + defaultdirname)
                settingsDialog.open()
            } else {
                setBookDir(filesystem.getDataDir(defaultdirname))
                readBookDir()
            }
        }
    }

    // If we need to resort, do it when hiding or showing this page
    onVisibleChanged: {
        if (needsort)
            listBooks()
        // If we are viewing recently read, then the book we had been reading is now at the top
        if (visible && sort == 0)
            gridview.positionViewAtBeginning()
    }

    Reader {
        id: coverReader
    }

    Timer {
        id: coverTimer
        interval: 1000
        repeat: false
        running: false
        triggeredOnStart: false

        onTriggered: localBooks.updateBookCover()
    }
    
    ListModel {
        id: bookModel
    }

    ListModel {
        id: perAuthorModel
        property bool needsclear: false
    }

    DefaultCover {
        id: defaultCover
	}

    Component {
        id: coverDelegate
        Item {
            width: gridview.cellWidth
            height: gridview.cellHeight

            Item {
                id: image
                anchors.fill: parent

                Image {
                    anchors {
                        fill: parent
                        leftMargin: gridmargin
                        rightMargin: gridmargin
                        topMargin: 1.5*gridmargin
                        bottomMargin: 1.5*gridmargin
                    }
                    fillMode: Image.PreserveAspectFit
                    source: {
                        if (model.cover == "ZZZerror")
                            return defaultCover.errorCover(model)
                        if (!model.fullcover)
                            return defaultCover.missingCover(model)
                        return model.fullcover
                    }
                    sourceSize.width: width
                    sourceSize.height: height
                    asynchronous: true

                    Text {
                        x: ((model.cover == "ZZZerror") ? 0.09375 : 0.125)*parent.width
                        y: 0.0625*parent.width
                        width: 0.8125*parent.width
                        height: parent.height/2 - 0.125*parent.width
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        color: defaultCover.textColor(model)
                        style: Text.Raised
                        styleColor: defaultCover.highlightColor(model, defaultCover.hue(model))
                        font.family: "URW Bookman L"
						visible: !model.fullcover
                        text: model.title
                    }

                    Text {
                        x: ((model.cover == "ZZZerror") ? 0.09375 : 0.125)*parent.width
                        y: parent.height/2 + 0.0625*parent.width
                        width: 0.8125*parent.width
                        height: parent.height/2 - 0.125*parent.width
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        color: defaultCover.textColor(model)
                        style: Text.Raised
                        styleColor: defaultCover.highlightColor(model, defaultCover.hue(model))
                        font.family: "URW Bookman L"
						visible: !model.fullcover
                        text: model.author
                    }
                }
            }

            DropShadow {
                anchors.fill: image
                radius: 12
                samples: 12
                source: image
                color: Qt.tint(Theme.palette.normal.background, "#65666666")
                verticalOffset: height * 0.025
                horizontalOffset: width * 0.025
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Save copies now, since these get cleared by loadFile (somehow...)
                    var filename = model.filename
                    var pasterror = model.cover == "ZZZerror"
                    if (loadFile(filename) && pasterror)
                        refreshCover(filename)
                }
                onPressAndHold: openInfoDialog(model)
            }
        }
    }

    Component {
        id: titleDelegate
        ItemDelegate {
			width: parent.width
			contentItem: Row {
				width: parent.width
				height: units.dp(45)
				spacing: width * 0.1
				Image {
					source: model.filename == "ZZZback" ? "image://theme/back" :
							model.cover == "ZZZnone" ? defaultCover.missingCover(model) :
							model.cover == "ZZZerror" ? "images/error_cover.svg" :
								model.cover
					height: parent.height * 0.75
					asynchronous: true
					sourceSize.height: height
					sourceSize.width: width
					//border: model.filename != "ZZZback" && model.cover != "ZZZerror"
					visible: model.filename != "ZZZback" || !wide
				}
				Column {
					height: parent.height
					spacing: units.dp(5)
					Text {
						text: model.title
						color: theme.palette.normal.backgroundText
						font.pointSize: units.dp(12)
					}
					Text {
						text: model.author
						color: theme.palette.normal.backgroundText
						font.pointSize: units.dp(9)
					}
				}
			}
			onClicked: {
				if (model.filename == "ZZZback") {
					perAuthorModel.needsclear = true
					adjustViews(false)
				} else {
					// Save copies now, since these get cleared by loadFile (somehow...)
					var filename = model.filename
					var pasterror = model.cover == "ZZZerror"
					if (loadFile(filename) && pasterror)
						refreshCover(filename)
				}
			}
			onPressAndHold: {
				if (model.filename != "ZZZback")
					openInfoDialog(model)
			}
		}
    }

    Component {
        id: authorDelegate
        
        ItemDelegate {
			width: parent.width
			contentItem: Row {
				width: parent.width
				height: units.dp(45)
				spacing: width * 0.1
				Image {
					source: model.count > 1 ? "image://theme/contact" :
							model.filename == "ZZZback" ? "image://theme/back" :
							model.cover == "ZZZnone" ? defaultCover.missingCover(model) :
							model.cover == "ZZZerror" ? "images/error_cover.svg" :
							model.cover
					height: parent.height * 0.75
					sourceSize.height: height
					sourceSize.width: width
					//border: model.filename != "ZZZback" && model.cover != "ZZZerror"
					visible: model.filename != "ZZZback" || !wide
				}
				Column {
					height: parent.height
					spacing: units.dp(5)
					Text {
						text: model.author || i18n.tr("Unknown Author")
						color: theme.palette.normal.backgroundText
						font.pointSize: units.dp(12)
					}
					Text {
						text: (model.count > 1) ? i18n.tr("%1 Book", "%1 Books", model.count).arg(model.count)
								: model.title
						color: theme.palette.normal.backgroundText
						font.pointSize: units.dp(9)
					}
				}
			}
			onClicked: {
                if (model.count > 1) {
                    listAuthorBooks(model.authorsort)
                    adjustViews(true)
                } else {
                    // Save copies now, since these get cleared by loadFile (somehow...)
                    var filename = model.filename
                    var pasterror = model.cover == "ZZZerror"
                    if (loadFile(filename) && pasterror)
                        refreshCover(filename)
                }
            }
            onPressAndHold: {
                if (model.count == 1)
                    openInfoDialog(model)
            }
		}
    }

    ListView {
        id: listview
        x: 0

        width: parent.width
        height: parent.height

        clip: true

        model: bookModel

        Behavior on x {
            id: widthAnimation
            NumberAnimation {
                duration: 333 //UbuntuAnimation.BriskDuration
                // TODO:
                //easing: UbuntuAnimation.StandardEasing

                onRunningChanged: {
                    if (!running && perAuthorModel.needsclear) {
                        perAuthorModel.clear()
                        perAuthorModel.needsclear = false
                    }
                }
            }
        }
        ScrollBar.vertical: ScrollBar { }
    }

    ListView {
        id: perAuthorListView
        anchors {
			top: listview.top
            left: listview.right
            bottom: listview.bottom
        }
        width: wide ? parent.width / 2 : parent.width
        clip: true

        model: perAuthorModel
        delegate: titleDelegate
        
        ScrollBar.vertical: ScrollBar { }
    }

    GridView {
        id: gridview
        
        anchors.fill: parent
        anchors.leftMargin: gridmargin
		anchors.rightMargin: gridmargin
        
        clip: true
        cellWidth: width / Math.floor(width/mingridwidth)
        cellHeight: cellWidth*1.5

        model: bookModel
        delegate: coverDelegate
        
        ScrollBar.vertical: ScrollBar { }
    }

    Item {
        anchors.fill: parent
        visible: bookModel.count == 0

        Column {
            anchors.centerIn: parent
            spacing: units.dp(16)
            width: Math.min(units.dp(400), parent.width - units.dp(8))

            Text {
                id: noBooksLabel
				anchors.horizontalCenter: parent.horizontalCenter
                text: i18n.tr("No Books in Library")
                font.pixelSize: units.dp(30)
				horizontalAlignment: Text.AlignHCenter
				width: parent.width
				wrapMode: Text.Wrap
            }

            Text {
                /*/ A path on the file system. /*/
                text: i18n.tr("Sturm Reader could not find any books for your library, and will " +
                              "automatically find all epub files in <i>%1</i>.  Additionally, any book " +
                              "opened will be added to the library.").arg(bookdir)
                wrapMode: Text.Wrap
				anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: i18n.tr("Get Books")
				anchors.horizontalCenter: parent.horizontalCenter
                highlighted: true
                width: parent.width
                onClicked: pageStack.push(importer.pickerPage)
            }

            Button {
                text: i18n.tr("Search Again")
				anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                onClicked: readBookDir()
            }
        }
    }

    
    function openInfoDialog(book) {
		infoDialog.open()
        infoDialog.bookTitle = book.title
        infoDialog.filename = book.filename

        var dirs = ["/.local/share/%1", "/.local/share/ubuntu-download-manager/%1"]
        for (var i=0; i<dirs.length; i++) {
            var path = filesystem.homePath() + dirs[i].arg(Qt.application.name)
            if (infoDialog.filename.slice(0, path.length) == path) {
                infoDialog.allowDelete = true
                break
            }
        }
        if (book.cover == "ZZZerror")
            infoDialog.coverSource = defaultCover.errorCover(book)
        else if (!book.fullcover)
            infoDialog.coverSource = defaultCover.missingCover(book)
        else
            infoDialog.coverSource = book.fullcover
    }
    
    Dialog {
		id: infoDialog
		visible: false	
		x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
		width: Math.min(parent.width*0.9, Math.max(parent.width * 0.5, units.dp(300)))
		height: Math.min(parent.height*0.9, Math.max(infoCover.height, infoColumn.height) + swipe.height + units.dp(100))
		
		modal: true
		standardButtons: Dialog.Close
		
		property alias coverSource: infoCover.source
		property alias bookTitle: titleLabel.text
		property alias filename: filenameLabel.text
		property alias allowDelete: swipe.visible
		
		header: ToolBar {
			width: parent.width
			height: titleLabel.height + units.dp(10)
			RowLayout {
				anchors.fill: parent
				Label {
					anchors.centerIn: parent
					id: titleLabel
					font.pixelSize: units.dp(27)
					color: theme.palette.normal.backgroundText
					wrapMode: Text.Wrap
					horizontalAlignment: Qt.AlignHCenter
					verticalAlignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}
			}
		}
		
		Item {
			id: dialogitem
			anchors.fill: parent

			Image {
				id: infoCover
				width: parent.width / 3
				height: parent.width / 2
				anchors {
					left: parent.left
					top: parent.top
				}
				fillMode: Image.PreserveAspectFit
				// Prevent blurry SVGs
				sourceSize.width: 2*localBooks.mingridwidth
				sourceSize.height: 3*localBooks.mingridwidth
			}

			Column {
				id: infoColumn
				anchors {
					left: infoCover.right
					right: parent.right
					top: parent.top
					leftMargin: units.dp(18)
				}
				spacing: units.dp(20)
				Text {
					id: filenameLabel
					width: parent.width
					horizontalAlignment: Text.AlignLeft
					font.pixelSize: units.dp(12)
					color: theme.palette.normal.backgroundText
					wrapMode: Text.WrapAnywhere
				}
				SwipeControl {
					id: swipe
					visible: false
					/*/ A control can be dragged to delete a file.  The deletion occurs /*/
					/*/ when the user releases the control. /*/
					actionText: i18n.tr("Release to Delete")
					/*/ A control can be dragged to delete a file. /*/
					notificationText: i18n.tr("Swipe to Delete")
					onTriggered: {
						filesystem.remove(infoDialog.filename)
						infoDialog.close()
						readBookDir()
					}
				}
			}
		}
	}

   Dialog {
		id: settingsDialog
		
		property string homepath: filesystem.homePath() + "/"
		
		x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
		width: Math.min(parent.width*0.9, Math.max(parent.width * 0.5, units.dp(300)))
		height: Math.min(parent.height*0.9, units.dp(600))
		
		modal: true
		
		header: ToolBar {
			width: parent.width
			RowLayout {
				anchors.fill: parent
				Label {
					text: firststart ? i18n.tr("Welcome to Sturm Reader!") : i18n.tr("Default Book Location")
					font.pixelSize: units.dp(27)
					color: theme.palette.normal.backgroundText
					elide: Label.ElideRight
					horizontalAlignment: Qt.AlignHCenter
					verticalAlignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}
			}
		}
		
		ColumnLayout {
			
			spacing: units.dp(20)
			
			/*/ Text precedes an entry for a file path. /*/
			Text {
				text: i18n.tr("Enter the folder in your home directory where your ebooks are or " +
							"should be stored.\n\nChanging this value will not affect existing " +
							"books in your library.")
				color: theme.palette.normal.backgroundText
			}
	
			TextField {
				id: pathfield
				text: {
					if (bookdir.substring(0, settingsDialog.length) == settingsDialog.homepath)
						return bookdir.substring(settingsDialog.homepath.length)
					return bookdir
				}
				onTextChanged: {
					var status = filesystem.exists(settingsDialog.homepath + pathfield.text)
					if (status == 0) {
						/*/ Create a new directory from path given. /*/
						useButton.text = i18n.tr("Create Directory")
						useButton.enabled = true
					} else if (status == 1) {
						/*/ File exists with path given. /*/
						useButton.text = i18n.tr("File Exists")
						useButton.enabled = false
					} else if (status == 2) {
						if (settingsDialog.homepath + pathfield.text == bookdir && !firststart)
							/*/ Read the books in the given directory again. /*/
							useButton.text = i18n.tr("Reload Directory")
						else
							/*/ Use directory specified to store books. /*/
							useButton.text = i18n.tr("Use Directory")
						useButton.enabled = true
					}
				}
			}

			Button {
				id: useButton
				onClicked: {
					var status = filesystem.exists(settingsDialog.homepath + pathfield.text)
					if (status != 1) { // Should always be true
						if (status == 0)
							filesystem.makeDir(settingsDialog.homepath + pathfield.text)
						setBookDir(settingsDialog.homepath + pathfield.text)
						useButton.enabled = false
						useButton.text = i18n.tr("Please wait...")
						cancelButton.enabled = false
						unblocker.start()
					}
				}
			}

			Timer {
				id: unblocker
				interval: 10
				onTriggered: {
					readBookDir()
					settingsDialog.close()
					firststart = false
				}
			}

			Button {
				id: cancelButton
				text: i18n.tr("Cancel")
				visible: !firststart
				onClicked: settingsDialog.close()
			}
		}
	}

    Dialog {
		id: settingsDisabledDialog
		
		header: ToolBar {
			id: settingsDisabledHeader
			width: parent.width
			RowLayout {
				anchors.fill: parent
				Label {
					text: i18n.tr("Default Book Location")
					font.pixelSize: units.dp(27)
					color: theme.palette.normal.backgroundText
					elide: Label.ElideRight
					horizontalAlignment: Qt.AlignHCenter
					verticalAlignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}
			}
		}
		
		x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
		width: Math.min(parent.width*0.9, Math.max(parent.width * 0.5, units.dp(300)))
		height: Math.min(parent.height*0.9, settingsDisabledColumn.height + settingsDisabledHeader.height + units.dp(50))
		
		modal: true
		
		/*/ A path on the file system. /*/
		Column {
			id: settingsDisabledColumn
			
			width: parent.width
			spacing: units.dp(20)
			
			Text {
				text: i18n.tr("Sturm Reader seems to be operating under AppArmor restrictions that prevent it " +
							"from accessing most of your home directory.  Ebooks should be put in " +
							"<i>%1</i> for Sturm Reader to read them.").arg(bookdir)
				color: theme.palette.normal.backgroundText
				width: parent.width
				wrapMode: Text.WordWrap
			}
			
			Button {
				width: parent.width * 0.7
				anchors.horizontalCenter: parent.horizontalCenter
				text: i18n.tr("Reload Directory")
				// We don't bother with the Timer trick here since we don't get this dialog on
				// first launch, so we shouldn't have too many books added to the library when
				// this button is clicked.s
				onClicked: {
					settingsDisabledDialog.close()
					readBookDir()
				}
			}

			Button {
				width: parent.width * 0.7
				anchors.horizontalCenter: parent.horizontalCenter
				highlighted: true
				text: i18n.tr("Close")
				onClicked: settingsDisabledDialog.close()
			}
		}
	}
}

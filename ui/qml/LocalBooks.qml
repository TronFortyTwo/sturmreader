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
import QtQuick.Layouts 1.3

Page {
	id: localBooks

	property alias sort: sorttabs.currentIndex
	property bool needsort: false
	property bool firststart: false
	property bool wide: width > scaling.dp(800)
	property string bookdir: ""
	property bool readablehome: false
	property string defaultdirname: "Books"
	property double gridmargin: scaling.dp(10)
	property double mingridwidth: scaling.dp(150)
	property bool authorinside: false
    
    header: Column {
		width: parent.width
		ToolBar {
			width: parent.width
			RowLayout {
				spacing: scaling.dp(2)
				anchors.top: parent.top
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				width: parent.width - scaling.dp(10)
				
				Label {
					text: gettext.tr("Library")
					font.pixelSize: headerTextSize()
					elide: Label.ElideRight
					horizontalAlignment: Qt.AlignLeft
					verticalAlignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}
				
				ToolButton {
					padding: scaling.dp(7)
					contentItem: Icon {
						anchors.centerIn: parent
						name: "add"
						color: colors.item
					}
					onClicked: importer.pick()
				}
				
				ToolButton {
					padding: scaling.dp(7)
					contentItem: Icon {
						anchors.centerIn: parent
						name: "info"
						color: colors.item
					}
					onClicked: pageStack.push("About.qml")
				}
				
				ToolButton {
					padding: scaling.dp(7)
					contentItem: Icon {
						anchors.centerIn: parent
						name: "settings"
						color: colors.item
					}
					onClicked: pageStack.push("Settings.qml")
				}
			}
		}
		TabBar {
			id: sorttabs
			width: parent.width
			TabButton {
				text: gettext.tr("Recently Read")
			}
			TabButton {
				text: gettext.tr("Title")
			}
			TabButton {
				text: gettext.tr("Author")
			}
		}
	}
    
	footer: ToolBar {
		visible: coverTimer.running || refreshTimer.running
		
		anchors.bottom: parent.bottom
		
		RowLayout {
			spacing: scaling.dp(20)
			
			BusyIndicator {
				id: updatingIndicator
				height: scaling.dp(45)
				width: height
			}
			
			Label {
				id: updatingLabel
				text: refreshTimer.running ? gettext.tr("Loading library...") : gettext.tr("Processing books data...");
				elide: Text.ElideRight
				verticalAlignment: Text.AlignVCenter
				Layout.fillWidth: true
			}
		}
	}
    
    onSortChanged: {
		authorinside = false;
    }
    
	// when closing perAuthor page reset model
	onAuthorinsideChanged: {
		if(!authorinside)
			perAuthorModel.clear();
	}
    
    function onFirstStart(db) {
        db.changeVersion(db.version, "1")
        noBooksLabel.text = gettext.tr("Welcome to Sturm Reader!")
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
		
		gridModel.update();
		titleModel.update();
		authorModel.update();
		
		localBooks.needsort = false;
    }
    
    
    function listAuthorBooks(authorsort) {
		perAuthorModel.update(authorsort);
		authorinside = true;
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

    // When there are new books in the library, this function takes the first of those books and extracts its data
    // It uses a timer to read books gradually, one at a time.
    function updateBookCover() {
        var db = openDatabase()
        db.transaction(function (tx) {
            var res = tx.executeSql("SELECT filename, title FROM LocalBooks WHERE authorsort == 'zzznull'")
			if (res.rows.length == 0) {
				// there are no more books unordered
				// stop the loop - and refresh authors
				authorModel.update();
				return
			}

            localBooks.needsort = true
            var title, author, authorsort, cover, fullcover, hash
            if (coverReader.load(res.rows.item(0).filename)) {
                var coverinfo = coverReader.getCoverInfo(scaling.dp(40), 2*mingridwidth)
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
                author = gettext.tr("Could not open this book.")
                authorsort = "zzzzerror"
                cover = "ZZZerror"
                fullcover = ""
                hash = ""
            }
            
            tx.executeSql("UPDATE LocalBooks SET title=?, author=?, authorsort=?, cover=?, " +
                          "fullcover=?, hash=? WHERE filename=?",
                          [title, author, authorsort, cover, fullcover, hash, res.rows.item(0).filename])
			
			// Search the book on all the views and update its data
            if (localBooks.visible) {
				for (var i=0; i<gridModel.count; i++) {
                    var book = gridModel.get(i)
                    if (book.filename == res.rows.item(0).filename) {
                        book.title = title
                        book.author = author
                        book.cover = cover
                        book.fullcover = fullcover
                        break
                    }
                }
                for (var i=0; i<titleModel.count; i++) {
                    var book = titleModel.get(i)
                    if (book.filename == res.rows.item(0).filename) {
                        book.title = title
                        book.author = author
                        book.cover = cover
                        book.fullcover = fullcover
                        break
                    }
                }
                for (var i=0; i<authorModel.count; i++) {
                    var book = authorModel.get(i)
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
        infoDialog.cover = book.cover
        infoDialog.fullcover = book.fullcover
        infoDialog.author = book.author
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
        addBookDir()
        listBooks()
        coverTimer.start()
    }

    function loadBookDir() {
        if (readablehome) {
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
        //readBookDir()
    }

    // We need to wait for main to be finished, so that the settings are available.
	function onMainCompleted() {
		refreshTimer.start();
	}
    
    Timer {
		id: refreshTimer
		repeat: false
		interval: 1
		running: false
		triggeredOnStart: false
		
		onTriggered: {
			// readBookDir() will trigger the loading of all files in the default directory
			// into the library.
			if (!firststart) {
				loadBookDir()
				readBookDir()
			} else {
                //readablehome = filesystem.readableHome()
                //if (readablehome) {
                //	setBookDir(filesystem.homePath() + "/" + defaultdirname)
                //	settingsDialog.open()
                //} else {
					setBookDir(filesystem.getDataDir(defaultdirname))
                    readBookDir()
                //}
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
    
	// contains the model for the grid view (recent books)
	ListModel {
		id: gridModel
		
		function update() {
			clear();
			
			var db = openDatabase()
			db.readTransaction(function (tx) {
				var res = tx.executeSql("SELECT filename, title, author, cover, fullcover, authorsort, count(*) FROM LocalBooks GROUP BY filename ORDER BY lastread DESC, title ASC")
				for (var i=0; i<res.rows.length; i++) {
					var item = res.rows.item(i)
					if (filesystem.exists(item.filename))
						append({filename: item.filename, title: item.title,
							author: item.author, cover: item.cover, fullcover: item.fullcover || "ZZZnull",
							authorsort: item.authorsort, count: item["count(*)"]})
				}
			})
		}
	}

	// contains the model for the title view
	ListModel {
		id: titleModel
		
		function update() {
			clear();
			
			var db = openDatabase()
			db.readTransaction(function (tx) {
				// We only need to GROUP BY in the author sort, but this lets us use the same
				// SQL logic for all three cases.
				var res = tx.executeSql("SELECT filename, title, author, cover, fullcover, authorsort, count(*) FROM LocalBooks GROUP BY filename ORDER BY title ASC")
				for (var i=0; i<res.rows.length; i++) {
					var item = res.rows.item(i)
					if (filesystem.exists(item.filename))
						append({filename: item.filename, title: item.title,
							author: item.author, cover: item.cover, fullcover: item.fullcover || "ZZZnull",
							authorsort: item.authorsort, count: item["count(*)"]})
				}
			})
		}
	}
    
	// contains the model for the author view
	ListModel {
		id: authorModel
		
		function update() {
			clear();
			
			var db = openDatabase()
			db.readTransaction(function (tx) {
				var res = tx.executeSql("SELECT filename, title, author, cover, fullcover, authorsort, count(*) FROM LocalBooks GROUP BY authorsort ORDER BY authorsort ASC")
				for (var i=0; i<res.rows.length; i++) {
					var item = res.rows.item(i)
					if (filesystem.exists(item.filename))
						append({filename: item.filename, title: item.title,
							author: item.author, cover: item.cover, fullcover: item.fullcover || "ZZZnull",
							authorsort: item.authorsort, count: item["count(*)"]})
				}
			})
		}
	}
    
	// contains the model for the single author books view
    ListModel {
        id: perAuthorModel
        
        function update(authorsort) {
			clear()
			
			var db = openDatabase()
			db.readTransaction(function (tx) {
				var res = tx.executeSql("SELECT filename, title, author, cover, fullcover FROM LocalBooks WHERE authorsort=? ORDER BY title ASC", [authorsort])
				for (var i=0; i<res.rows.length; i++) {
					var item = res.rows.item(i)
					if (filesystem.exists(item.filename))
						append({filename: item.filename, title: item.title,
										author: item.author, cover: item.cover, fullcover: item.fullcover})
				}
			})
			append({filename: "ZZZback", title: gettext.tr("Back"), author: "", cover: ""})
		}
    }

    DefaultCover {
        id: defaultCover
	}
	
    SwipeView {
		id: swiper
		
		anchors.fill: parent
		
		currentIndex: localBooks.sort
		onCurrentIndexChanged: {
			localBooks.sort = currentIndex
		}
		
		Item {
			GridView {
				id: gridview
			
				anchors.fill: parent
				anchors.leftMargin: gridmargin
				anchors.rightMargin: gridmargin
        
				clip: true
				cellWidth: width / Math.floor(width/mingridwidth)
				cellHeight: cellWidth*1.5

				model: gridModel
				delegate: CoverDelegate {
					width: gridview.cellWidth
					height: gridview.cellHeight
					
					cover: model.cover
					fullcover: model.fullcover
					title: model.title
					author: model.author
					coverMargin: gridmargin
					
					MouseArea {
						anchors.fill: parent
						onClicked: {
							// Save copies now, since these get cleared by loadFile (somehow...)
							var filename = model.filename
							var pasterror = model.cover == "ZZZerror"
							if (loadFile(filename) && pasterror)
								refreshCover(filename)
						}
						onPressAndHold: {
							openInfoDialog(model);
						}
					}
				}
        
				ScrollBar.vertical: ScrollBar { }
			}
		}
		
    
		ListView {
			id: titleview

			clip: true

			delegate: SuperDelegate {
				width: titleview.width
				image_source: model.filename == "ZZZback" ? "Icons/go-previous.svg" :
					model.cover == "ZZZnone" ? defaultCover.missingCover(model) :
					model.cover == "ZZZerror" ? "images/error_cover.svg" : model.cover
				main_text: model.title
				sub_text: model.author
				onClicked: {
					if (model.filename == "ZZZback") {
						authorinside = false;
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
			model: titleModel

			ScrollBar.vertical: ScrollBar { }
		}

		Item {
			ListView {
				id: authorview
				
				visible: wide || !authorinside
				anchors.left: parent.left
				height: parent.height
				width: wide ? Math.floor(parent.width * 0.5) : parent.width
				
				clip: true
				
				model: authorModel
				delegate: SuperDelegate {
					width: authorview.width
					main_text: model.author || gettext.tr("Unknown Author")
					sub_text: (model.count > 1) ? gettext.tr("%1 Book", "%1 Books", model.count).arg(model.count) : model.title
					image_source: model.count > 1 ? "Icons/avatar.svg" :
						model.filename == "ZZZback" ? "Icons/go-previous.svg" :
						model.cover == "ZZZnone" ? defaultCover.missingCover(model) :
						model.cover == "ZZZerror" ? "images/error_cover.svg" :
						model.cover
					onClicked: {
						if (model.count > 1) {
							listAuthorBooks(model.authorsort)
							//adjustViews(true)
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
				
				ScrollBar.vertical: ScrollBar { }
			}
			
			ListView {
				id: perAuthorListView
				height: parent.height
				anchors.right: parent.right
				width: wide ? Math.floor(parent.width * 0.5) : parent.width
				visible: wide || !authorview.visible
				clip: true

				model: perAuthorModel
				delegate: SuperDelegate {
					width: perAuthorListView.width
					visible: model.filename != "ZZZback" || !wide
					image_source: model.filename == "ZZZback" ? "Icons/go-previous.svg" :
						model.cover == "ZZZnone" ? defaultCover.missingCover(model) :
						model.cover == "ZZZerror" ? "images/error_cover.svg" : model.cover
					main_text: model.title
					sub_text: model.author
					onClicked: {
						if (model.filename == "ZZZback") {
							authorinside = false;
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

				ScrollBar.vertical: ScrollBar { }
			}
		}
	}
	// Bottom page indicator for the swiper
	PageIndicator {
		id: indicator

		count: swiper.count
		currentIndex: swiper.currentIndex

		anchors.bottom: swiper.bottom
		anchors.horizontalCenter: swiper.horizontalCenter
	}

    Item {
        anchors.fill: parent
        visible: gridModel.count == 0 && !refreshTimer.running

        Column {
            anchors.centerIn: parent
            spacing: scaling.dp(16)
            width: Math.min(scaling.dp(600), parent.width - scaling.dp(8))

            Label {
                id: noBooksLabel
				anchors.horizontalCenter: parent.horizontalCenter
                text: gettext.tr("No Books in Library")
				font.pixelSize: scaling.dp(25)
				horizontalAlignment: Text.AlignHCenter
				width: parent.width
				wrapMode: Text.Wrap
            }

            Label {
                /*/ A path on the file system. /*/
                text: gettext.tr("Sturm Reader could not find any books for your library, and will " +
                              "automatically find all epub files in <i>%1</i>.  Additionally, any book " +
                              "opened will be added to the library.").arg(bookdir)
                wrapMode: Text.Wrap
				anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: gettext.tr("Get Books")
				anchors.horizontalCenter: parent.horizontalCenter
                highlighted: true
                width: parent.width
                onClicked: importer.pick()
            }

            Button {
                text: gettext.tr("Search Again")
				anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                onClicked: refreshTimer.start();
            }
        }
    }
    
    Dialog {
		id: infoDialog
		visible: false
		x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
		width: Math.min(parent.width*0.9, Math.max(parent.width * 0.5, scaling.dp(300)))
		height: Math.min(parent.height*0.9, Math.max(infoCover.height, infoColumn.height) + swipe.height + infoToolBar.height + scaling.dp(10))
		
		modal: true
		standardButtons: Dialog.Close
		
		property alias bookTitle: titleLabel.text
		property alias filename: filenameLabel.text
		property alias allowDelete: swipe.visible
		property alias cover: infoCover.cover
		property alias fullcover: infoCover.fullcover
		property alias author: infoCover.author
		
		header: ToolBar {
			id: infoToolBar
			width: parent.width
			height: titleLabel.height + scaling.dp(10)
			Label {
				width: parent.width
				anchors.verticalCenter: parent.verticalCenter
				id: titleLabel
				font.pixelSize: headerTextSize()
				wrapMode: Text.Wrap
				horizontalAlignment: Qt.AlignHCenter
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
			}
		}
		
		Item {
			id: dialogitem
			anchors.fill: parent

			CoverDelegate {
				id: infoCover
				
				anchors.left: parent.left
				anchors.top: parent.top
				
				width: parent.width / 3
				height: parent.width / 2
				title: infoDialog.bookTitle
			}

			Column {
				id: infoColumn
				anchors {
					left: infoCover.right
					right: parent.right
					top: parent.top
					leftMargin: scaling.dp(18)
				}
				spacing: scaling.dp(20)
				Label {
					id: filenameLabel
					width: parent.width
					horizontalAlignment: Text.AlignLeft
					font.pixelSize: scaling.dp(12)
					wrapMode: Text.WrapAnywhere
				}
				SwipeControl {
					id: swipe
					visible: false
					/*/ A control can be dragged to delete a file.  The deletion occurs /*/
					/*/ when the user releases the control. /*/
					actionText: gettext.tr("Release to Delete")
					/*/ A control can be dragged to delete a file. /*/
					notificationText: gettext.tr("Swipe to Delete")
					onTriggered: {
						infoDialog.close()
						filesystem.remove(infoDialog.filename)

						refreshTimer.start();
					}
				}
			}
		}
	}
}

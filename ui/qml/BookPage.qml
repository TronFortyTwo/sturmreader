/* Copyright 2013-2015 Robert Schroll
 * Copyright 2020-2021 Emanuele Sorce - emanuele.sorce@hotmail.com
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import "historystack.js" as History

import Browser 1.0

Page {
	id: bookPage
    
	property alias url: bookWebView.url
	property var currentChapter: null
	property var history: new History.History(updateNavButtons)
	property bool navjump: false
	property bool canBack: false
	property bool canForward: false
	property bool isBookReady: false
	property bool doPageChangeAsSoonAsReady: false
    
	property string book_componentId;
	property real book_percent;
	
	// picture (i.e. pdf) has limited options
	property bool pictureBook: false;
	
	property int pdf_pageNumber: 0;
	property int pdf_numberOfPages: 0;
    
	// book settings manager
	property BookSettings bookSettings: BookSettings { parent: bookPage }
	// outline
	property ListModel contentsListModel: ListModel {}
	property ListModel pagesTumblerModel: ListModel {}
	
	signal contentOpened()

	Dialog {
		id: content
		width: Math.min(parent.width, scaling.dp(750))
		height: Math.max(parent.height * 0.75, Math.min(parent.height, scaling.dp(500)))
		y: (parent.height - height) * 0.5
		x: (parent.width - width) * 0.5
		dim: true
		
		property alias pdf_newPage: pageSlider.value
		
		header: Column {
			width: parent.width
			ToolBar {
				width: parent.width
				RowLayout {
					anchors.fill: parent
					Label {
						text: gettext.tr("Contents")
						font.pixelSize: headerTextSize()
						elide: Label.ElideRight
						horizontalAlignment: Qt.AlignHCenter
						verticalAlignment: Qt.AlignVCenter
						Layout.fillWidth: true
					}
				}
			}
			TabBar {
				id: sorttabs
				width: parent.width
				TabButton {
					text: gettext.tr("Outline")
					onClicked: {
						pagesLoader.visible = false;
						outlineLoader.visible = true;
						content.standardButtons = Dialog.Cancel;
					}
				}
				TabButton {
					text: gettext.tr("Pages")
					visible: pictureBook && !appsettings.legacypdf
					onClicked: {
						outlineLoader.visible = false;
						pagesLoader.visible = true;
						content.standardButtons = Dialog.Cancel | Dialog.Ok;
					}
				}
			}
		}
		
		standardButtons: Dialog.Cancel
		
		Item {
			id: outlineLoader
			
			anchors.fill: parent
			
			ListView {
				id: contentsListView
				anchors.fill: parent
				visible: contentsListModel.count > 0

				model: contentsListModel
				delegate: ItemDelegate {
					width: parent.width
					highlighted: bookPage.currentChapter == model.src
					text: (new Array(model.level + 1)).join("    ") +
							model.title.replace(/(\n| )+/g, " ").replace(/^%PAGE%/, gettext.tr("Page"))
					onClicked: {
						bookLoadingStart();
						bookWebView.runJavaScript('moveToChapter("' + model.src + '")');
						content.close();
					}
				}

				Connections {
					target: bookPage
					onContentOpened: {
						for (var i=0; i<contentsListModel.count; i++) {
							if (contentsListModel.get(i).src == bookPage.currentChapter) {
								contentsListView.positionViewAtIndex(i, ListView.Center);
								break;
							}
						}
					}
				}
				ScrollBar.vertical: ScrollBar {}
			}
			Label {
				anchors.centerIn: parent
				visible: contentsListModel.count == 0
				text: gettext.tr("No outline available")
			}
		}
		
		Item {
			id: pagesLoader
			anchors.fill: parent
			visible: false
			
			property alias slider: pageSlider
			
			Column {
				width: parent.width
				anchors.leftMargin: scaling.dp(10)
				anchors.rightMargin: scaling.dp(10)
				
				spacing: scaling.dp(15)
				
				onVisibleChanged: {
					pagesLoader.slider.value = pdf_pageNumber;
				}
				
				Label {
					width: parent.width
					horizontalAlignment: Text.AlignHCenter
					text: gettext.tr("Page") + " " + pagesLoader.slider.value + "/" + (pdf_numberOfPages)
					font.pixelSize: scaling.dp(16)
				}
				RowLayout {
					width: parent.width
					Button {
						Layout.alignment: Qt.AlignLeft
						text: "-"
						font.pixelSize: scaling.dp(16)
						onClicked: pagesTumbler.currentIndex -= 1
					}
					Tumbler {
						Layout.alignment: Qt.AlignHCenter
						id: pagesTumbler
						rotation: -90
						wrap: false
						model: pagesTumblerModel
						delegate: Label {
							text: model.num
							rotation: 90
							font.weight: (model.num == pagesTumbler.currentIndex+1) ? Font.Bold : Font.Normal
							font.pixelSize: (model.num == pagesTumbler.currentIndex+1) ? scaling.dp(16) : scaling.dp(13)
							width: scaling.dp(60)
							height: scaling.dp(60)
							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
						}
						onCurrentIndexChanged: {
							if (pagesLoader.slider.value != currentIndex+1)
								pagesLoader.slider.value = currentIndex+1;
						}
					}
					Button {
						Layout.alignment: Qt.AlignRight
						text: "+"
						font.pixelSize: scaling.dp(16)
						onClicked: pagesTumbler.currentIndex += 1
					}
				}
			}
			RowLayout {
				id: sliderRow
				width: parent.width
				anchors.bottom: parent.bottom
				Slider {
					id: pageSlider
					Layout.fillWidth: true
					from: 1
					to: pdf_numberOfPages
					stepSize: 1
					value: pdf_pageNumber
					onValueChanged: {
						if (pagesTumbler.currentIndex != value-1)
							pagesTumbler.currentIndex = value-1;
					}
					snapMode: Slider.SnapAlways
				}
				Label {
					width: scaling.dp(50)
					text: Math.floor(100 * pageSlider.value / pdf_numberOfPages) + "%"
				}
			}
		}
		
		onAccepted: {
			var locus = {pageNumber: pdf_newPage}
			bookWebView.runJavaScript("moveToLocus(" + JSON.stringify(locus) + ")");
		}
	}

	Drawer {
		id: controls
		width: parent.width
		height: controlRect.height
		edge: Qt.BottomEdge
		modal: false
		
		Rectangle {
			id: controlRect
			
			antialiasing: false
			color: colors.background
			
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			height: childrenRect.height
			width: parent.width
			
			// relaxed layout uses more space, nicer on wider screens
			// there is one button more on the right, so we check there
			property bool relaxed_layout: width * 0.5 >= jump_button.width + content_button.width + settings_button.width
			
			// reduce button size when even not relaxed layout not enought
			// 7 is the number of buttons
			// Not 100% accurate alghorithm, but this convers just edge cases (very small phone display)
			property int max_button_size: width / 7 - scaling.dp(1)
			
			FloatingButton {
				id: home_button
				anchors.left: parent.left
				max_size: controlRect.max_button_size
				buttons: [
					Action {
						icon.name: "go-home"
						onTriggered: {
							// turn stuff off and exit
							content.close();
							controls.close();
							controls.interactive = false;
							pageStack.pop()
							mainView.title = mainView.defaultTitle
						}
					}
				]
			}
			FloatingButton {
				id: history_button
				anchors.right: jump_button.left
				max_size: controlRect.max_button_size
				buttons: [
					Action {
						icon.name: "undo"
						enabled: canBack
						onTriggered: {
							var locus = history.goBackward()
							if (locus !== null) {
								navjump = true;
								bookLoadingStart()
								bookWebView.runJavaScript("moveToLocus(" + locus + ")");
							}
						}
					},
					Action {
						icon.name: "redo"
						enabled: canForward
						onTriggered: {
							var locus = history.goForward()
							if (locus !== null) {
								navjump = true;
								bookLoadingStart()
								bookWebView.runJavaScript("moveToLocus(" + locus + ")");
							}
						}
					}
				]
			}
			FloatingButton {
				id: jump_button
				anchors.right: content_button.left
				anchors.rightMargin: controlRect.relaxed_layout ? parent.width * 0.5 - content_button.width - settings_button.width - width : 0
				max_size: controlRect.max_button_size
				
				buttons: [
					Action {
						icon.name: "go-previous"
						onTriggered: {
							bookLoadingStart()
							bookWebView.runJavaScript("moveToPageRelative(-10)");
						}
					},
					Action {
						icon.name: "go-next"
						onTriggered: {
							bookLoadingStart()
							bookWebView.runJavaScript("moveToPageRelative(10)");
						}
					}
				]
			}
			FloatingButton {
				id: content_button
				anchors.right: settings_button.left
				max_size: controlRect.max_button_size
				buttons: [
					Action {
						icon.name: "book"
						onTriggered: {
							content.open();
							contentOpened();
							controls.close();
						}
					}
				]
			}
			FloatingButton {
				id: settings_button
				anchors.right: parent.right
				max_size: controlRect.max_button_size
				buttons: [
					Action {
						icon.name: "settings"
						onTriggered: {
							bookSettings.openDialog()
							controls.close();
						}
					}
				]
			}
		}
	}

    BusyIndicator {
        id: loadingIndicator
        width: scaling.dp(50)
        height: scaling.dp(50)
        anchors.centerIn: parent
        opacity: 1
        running: opacity != 0
    }
	
	Label {
		visible: pictureBook
		text: "" + (pdf_pageNumber == 0 ? "-" : pdf_pageNumber) + "/" + (pdf_numberOfPages == 0 ? "-" : pdf_numberOfPages)
		anchors.bottom: parent.bottom
		anchors.bottomMargin: scaling.dp(5)
		anchors.rightMargin: scaling.dp(5)
		anchors.right: parent.right
		font.pixelSize: scaling.dp(12)
		// TODO: page number is not visible if pdf page is of the same color on landscape
		color: bookSettings.infoColor
	}
	
	Browser {
		id: bookWebView
		anchors.fill: parent
		opacity: 0
		
		onActiveFocusChanged: {
			if(activeFocus)
				controls.close();
		}
		
		// TODO: doesn't seem to work
		Keys.onPressed: {
			if (event.key == Qt.Key_Right || event.key == Qt.Key_Down || event.key == Qt.Key_Space
					|| event.key == Qt.Key_Period) {
				bookLoadingStart();
				bookWebView.runJavaScript("moveToPageRelative(1)");
				event.accepted = true;
			} else if (event.key == Qt.Key_Left || event.key == Qt.Key_Up
					|| event.key == Qt.Key_Backspace || event.key == Qt.Key_Comma) {
				bookLoadingStart();
				bookWebView.runJavaScript("moveToPageRelative(-1)");
				event.accepted = true;
			}
		}
	}
	
	function parseApiCall( message ) {
		console.log("Book: " + message);
		
		var msg = message.split(" ");
		
		if(msg[0] == "Jumping") {
			bookPage.onJumping([msg[1], msg[2]]);
		} else if(msg[0] == "UpdatePage") {
			if(!isBookReady) {
				doPageChangeAsSoonAsReady = true;
			} else {
				bookLoadingCompleted();
				bookPage.updateSavedPage();
			}
		} else if(msg[0] == "startLoading") {
			bookLoadingStart();
		} else if(msg[0] == "Ready") {
			isBookReady = true;
			if(doPageChangeAsSoonAsReady) {
				bookPage.updateSavedPage();
				doPageChangeAsSoonAsReady = false;
			}
			bookLoadingCompleted();
			controls.open();
		} else if(msg[0] == "setContent") {
			contentsListModel.clear();
			if(msg.length > 2)
				for(var i=2; i<msg.length; i++) msg[1] += " " + msg[i];
			var con = JSON.parse(msg[1]);
			for(var i=0; i<con.length; i++) contentsListModel.append(con[i]);
		} else if(msg[0] == "status_requested") {
			bookWebView.runJavaScript("statusUpdate()");
		} else if(msg[0] == "chapter") {
			if(msg.length > 2)
				for(var i=2; i<msg.length; i++) msg[1] += " " + msg[i];
			currentChapter = JSON.parse(msg[1]);
		} else if(msg[0] == "percent") {
			book_percent = Number(msg[1]);
		} else if(msg[0] == "componentId") {
			book_componentId = msg[1];
		} else if(msg[0] == "pageNumber") {
			pdf_pageNumber = Number(msg[1]);
		} else if(msg[0] == "numberOfPages") {
			pdf_numberOfPages = Number(msg[1]);
			pagesTumblerModel.clear();
			for (var i = 1; i <= pdf_numberOfPages; i += 1)
				pagesTumblerModel.append({"num": (i)});
		} else if(msg[0] == "ok") {
			bookLoadingCompleted();
		} else if(msg[0] == "monocle:notfound") {
			// This is caused by some bug - we prevent the app from freeze in loading at least
			bookLoadingCompleted()
		} else if(msg[0] == "monocle:link:external") {
			var comp_id = msg[1].split("127.0.0.1:" + server.port + "/")[1];
			runJavaScript("moveToChapter('" + comp_id + "')");
		} else if(msg[0] == "pictureBook") {
			pictureBook = true;
		// debug messages
		} else if(msg[0] == "#") {}
		// not handled messages
		else console.log("ignored");
	}
	
	function bookLoadingStart(){
		bookWebView.opacity = 0;
		loadingIndicator.opacity = 1;
	}
	function bookLoadingCompleted(){
		bookWebView.opacity = 1;
		loadingIndicator.opacity = 0;
	}

    function updateNavButtons(back, forward) {
        canBack = back
        canForward = forward
    }

    function parseContents(contents, level) {
        if (level === undefined) {
            level = 0
            contentsListModel.clear()
        }
        for (var i in contents) {
            var chp = contents[i]
            chp.level = level
            contentsListModel.append(chp)
            if (chp.children !== undefined)
                parseContents(chp.children, level + 1)
        }
    }

    function onJumping(locuses) {
        if (navjump)
            navjump = false
        else
            history.add(locuses[0], locuses[1])
    }

	function updateSavedPage() {
		setBookSetting("locus", {
			// monocle
			componentId: book_componentId,
			percent: Number(book_percent),
			// pdfjs
			pageNumber: pdf_pageNumber
		})
		pageMetric.turnPage()
	}

	Component.onCompleted: {
		server.reader.contentsReady.connect(parseContents)
		bookSettings.loadForBook();
		bookSettings.update();
	}
}

/* Copyright 2013-2015 Robert Schroll
 * Copyright 2020 Emanuele Sorce - emanuele.sorce@hotmail.com
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtWebEngine 1.7

import FontList 1.0
import Units 1.0

import "components"
import "not-portable"

import "historystack.js" as History

PageWithBottomEdge {
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

    focus: true
    Keys.onPressed: {
        if (event.key == Qt.Key_Right || event.key == Qt.Key_Down || event.key == Qt.Key_Space
                || event.key == Qt.Key_Period) {
			bookLoadingStart()
			bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: 1}))")
        } else if (event.key == Qt.Key_Left || event.key == Qt.Key_Up
                   || event.key == Qt.Key_Backspace || event.key == Qt.Key_Comma) {
			bookLoadingStart()
			bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: -1}))")
		}
        event.accepted = true
    }

    onVisibleChanged: {
        //mainView.automaticOrientation = !visible
        if (visible == false) {
            // Reset things for the next time this page is opened
			isBookReady = false
			doPageChangeAsSoonAsReady = false
            if (history)
                history.clear()
            url = ""
			bookLoadingStart()
            closeContent()
        } else {
            bookStyles.loadForBook()
        }
    }

    ListModel {
        id: contentsListModel
    }

    BusyIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        opacity: 1
        running: opacity != 0
    }
    
    function bookLoadingStart(){
		bookWebView.opacity = 0
		loadingIndicator.opacity = 1
	}
	function bookLoadingCompleted(){
		bookWebView.opacity = 1
		loadingIndicator.opacity = 0
	}
    
	WebEngineView {
		id: bookWebView
		anchors.fill: parent
		opacity: 0
		focus: false
		onJavaScriptConsoleMessage: function(level, message, linen, sourceID) {
			console.log("Book: " + message + " | level: " + level + " | line: " + linen + " | source: " + sourceID);
		
			var msg = message.split(" ");
			
			if(msg[0] == "Jumping") {
				bookPage.onJumping([msg[1], msg[2]]);
			}
			else if(msg[0] == "PageChange") {
				if(!isBookReady)
					doPageChangeAsSoonAsReady = true;
				else
				{
					bookLoadingCompleted()
					bookPage.onPageChange()
				}
			}
			else if(msg[0] == "Ready") {
				isBookReady = true
				if(doPageChangeAsSoonAsReady) {
					bookPage.onPageChange()
					doPageChangeAsSoonAsReady = false
				}
				bookLoadingCompleted()
				openControls()
			}
			else if(msg[0] == "status_requested") {
				bookWebView.runJavaScript("statusUpdate()");
			}
			else if(msg[0] == "chapter") {
				currentChapter = JSON.parse(msg[1]);
			}
			else if(msg[0] == "percent") {
				book_percent = Number(msg[1]);
			}
			else if(msg[0] == "componentId") {
				book_componentId = msg[1];
			}
			else if(msg[0] == "monocle:notfound") {
				// TODO: this should not happen
				bookLoadingCompleted()
			}
			// debug messages
			else if(msg[0] == "#") {}
			else
				console.log("not handled");
		}
		
		onActiveFocusChanged: {
			if(activeFocus)
				closeControls()
			// reject attempts to give WebView focus
			focus = false;
		}
	}
	
	Metrics {
		id: pageMetric
	}

    bottomEdgeControls: Rectangle {
		
		antialiasing: false
		color: theme.palette.normal.background
		
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height
        
        // relaxed layout uses more space, nicer on wider screens
        // there is one button more on the right, so we check there
		property bool relaxed_layout: parent.width * 0.5 >= jump_button.width + content_button.width + settings_button.width
		
		// reduce button size when even not relaxed layout not enought
		// 7 is the number of buttons
		// Not 100% accurate alghorithm, but this convers just edge cases (very small phone display)
		property int max_button_size: width / 7 - units.dp(1.5)
		
        FloatingButton {
			id: home_button
            anchors.left: parent.left
            max_size: max_button_size
            buttons: [
                Action {
                    iconName: "go-home"
                    onTriggered: {
						// turn stuff off and exit
						closeContent()
						closeControls()
						turnControlsOff()
						pageStack.pop()
						mainView.title = mainView.defaultTitle
                    }
                }
            ]
        }
		FloatingButton {
			id: history_button
			anchors.right: jump_button.left
			max_size: max_button_size
            buttons: [
                Action {
                    iconName: "undo"
                    enabled: canBack
                    onTriggered: {
                        var locus = history.goBackward()
                        if (locus !== null) {
							navjump = true;
							bookLoadingStart()
							bookWebView.runJavaScript("reader.moveTo(" + locus + ")");
                        }
                    }
                },
                Action {
                    iconName: "redo"
                    enabled: canForward
                    onTriggered: {
                        var locus = history.goForward()
                        if (locus !== null) {
							navjump = true;
							bookLoadingStart()
							bookWebView.runJavaScript("reader.moveTo(" + locus + ")");
                        }
                    }
                }
            ]
        }
        FloatingButton {
			id: jump_button
			anchors.right: content_button.left
			anchors.rightMargin: relaxed_layout ? parent.width * 0.5 - content_button.width - settings_button.width - width : 0
			max_size: max_button_size
			
			buttons: [
				Action {
					iconName: "go-previous"
					onTriggered: {
						bookLoadingStart()
						bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: -10}))");
					}
				},
				Action {
					iconName: "go-next"
					onTriggered: {
						bookLoadingStart()
						bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: 10}))");
					}
				}
			]
		}
        FloatingButton {
			id: content_button
            anchors.right: settings_button.left
            max_size: max_button_size
            buttons: [
                Action {
                    iconName: "book"
                    onTriggered: {
						openContent()
						closeControls()
                    }
                }
            ]
        }
        FloatingButton {
			id: settings_button
			anchors.right: parent.right
			max_size: max_button_size
            buttons: [
                Action {
                    iconName: "settings"
                    onTriggered: {
                        stylesDialog.open()
                        closeControls()
                    }
                }
            ]
        }
    }

    bottomEdgePageComponent: Item {
        ListView {
            id: contentsListView
            anchors.fill: parent

            model: contentsListModel
            delegate: ItemDelegate {
				width: parent.width
				highlighted: bookPage.currentChapter == model.src
				text: (new Array(model.level + 1)).join("    ") +
						model.title.replace(/(\n| )+/g, " ").replace(/^%PAGE%/, i18n.tr("Page"))
				onClicked: {
					bookLoadingStart()
					console.log(model.src)
					bookWebView.runJavaScript('reader.skipToChapter("' + model.src + '")');
					closeContent()
				}
            }

            Connections {
                target: bookPage
                onContentOpened: {
                    for (var i=0; i<contentsListModel.count; i++) {
                        if (contentsListModel.get(i).src == bookPage.currentChapter)
							contentsListView.positionViewAtIndex(i, ListView.Center)
                    }
                }
            }
            ScrollBar.vertical: ScrollBar {}
        }
    }

    Item {
        id: bookStyles
        property bool loading: false
        property bool atdefault: false

        property string textColor
        property string fontFamily
        property real lineHeight
        property real fontScale
        property string background
        property real margin
        property real marginv
        property real bumper

        property var defaults: ({
            textColor: "#222",
            fontFamily: "Default",
            lineHeight: 1,
            fontScale: 1,
            background: "url(.background_paper@30.png)",
            margin: 0,
            marginv: 0
        })

        //onTextColorChanged: update()  // This is always updated with background
        onFontFamilyChanged: update()
        onLineHeightChanged: update()
        onFontScaleChanged: update()
        onBackgroundChanged: update()
        onMarginChanged: update()

        function load(styles) {
            loading = true
            textColor = styles.textColor || defaults.textColor
            fontFamily = styles.fontFamily || defaults.fontFamily
            lineHeight = styles.lineHeight || defaults.lineHeight
            fontScale = styles.fontScale || defaults.fontScale
            background = styles.background || defaults.background
            margin = styles.margin || (server.reader.pictureBook ? 0 : defaults.margin)
            marginv = styles.marginv || (server.reader.pictureBook ? 0 : defaults.marginv)
            bumper = server.reader.pictureBook ? 0 : 1
            loading = false
        }

        function loadForBook() {
            var saved = getBookSetting("styles") || {}
            load(saved)
        }

        function asObject() {
            return {
                textColor: textColor,
                fontFamily: fontFamily,
                lineHeight: lineHeight,
                fontScale: fontScale,
                background: background,
                margin: margin,
                marginv: marginv,
                bumper: bumper
            }
        }

        function update() {
            if (loading)
                return
                
			bookLoadingStart()
			
            //Messaging.sendMessage("Styles", asObject())
            // this one below should be improved
			bookWebView.runJavaScript("styleManager.updateStyles({" +
				"'textColor':'" + textColor +
				"','fontFamily':'" + fontFamily +
				"','lineHeight':'" + lineHeight +
				"','fontScale':'" + fontScale +
				"','background':'" + background +
				"','margin':'" + margin +
				"','marginv':'" + marginv +
				"','bumper':'" + bumper +
			"'});");
			setBookSetting("styles", asObject());
			atdefault = (JSON.stringify(asObject()) == JSON.stringify(defaults));
        }

        function resetToDefaults() {
            load({})
            update()
        }

        function saveAsDefault() {
            setSetting("defaultBookStyle", JSON.stringify(asObject()))
            defaults = asObject()
            atdefault = true
        }

        Component.onCompleted: {
            var targetwidth = 60
            var widthgu = width/units.dp(8)
            if (widthgu > targetwidth)
                // Set the margins to give us the target width, but no more than 30%.
                defaults.margin = Math.round(Math.min(50 * (1 - targetwidth/widthgu), 30))

            var saveddefault = getSetting("defaultBookStyle")
            var savedvals = {}
            if (saveddefault != null)
                savedvals = JSON.parse(saveddefault)
            for (var prop in savedvals)
                if (prop in defaults)
                    defaults[prop] = savedvals[prop]

            if (savedvals.marginv == undefined && widthgu > targetwidth)
                // Set the vertical margins to be the same as the horizontal, but no more than 5%.
                defaults.marginv = Math.min(defaults.margin, 5)
        }
    }

    function getBookStyles() {
        return bookStyles.asObject()
    }

    FontLister {
        id: fontLister

        property var fontList: ["Default", "Bitstream Charter", "Ubuntu", "URW Bookman L", "URW Gothic L"]

        Component.onCompleted: {
            var familyList = families()
            var possibleFamilies = [["Droid Serif", "Nimbus Roman No9 L", "FreeSerif"],
                                    ["Droid Sans", "Nimbus Sans L", "FreeSans"]]
            for (var j=0; j<possibleFamilies.length; j++) {
                for (var i=0; i<possibleFamilies[j].length; i++) {
                    if (familyList.indexOf(possibleFamilies[j][i]) >= 0) {
                        fontList.splice(2, 0, possibleFamilies[j][i])
                        break
                    }
                }
            }
        }
    }

    FontLoader {
        source: Qt.resolvedUrl("../html/fonts/Bitstream Charter.ttf")
    }

    FontLoader {
        source: Qt.resolvedUrl("../html/fonts/URW Bookman L.ttf")
    }

    FontLoader {
        source: Qt.resolvedUrl("../html/fonts/URW Gothic L.ttf")
    }

    Dialog {
		id: stylesDialog
		property real labelwidth: width * 0.3
		visible: false
		
		x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
		width: Math.min(parent.width, Math.max(parent.width * 0.5, units.dp(450)))
		height: Math.min(parent.height*0.9, stylesFlickable.contentHeight + stylesToolbar.height + units.dp(50))
		
		modal: true
		
		header: ToolBar {
			id: stylesToolbar
			width: parent.width
			RowLayout {
				anchors.fill: parent
				Label {
					text: i18n.tr("Book Settings")
					font.pixelSize: units.dp(27)
					color: theme.palette.normal.backgroundText
					elide: Label.ElideRight
					horizontalAlignment: Qt.AlignHCenter
					verticalAlignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}
				
				BusyIndicator {
					width: height
					height: units.dp(25)
					anchors.right: parent.right
					opacity: loadingIndicator.opacity
					running: opacity != 0
				}
			}
		}
		
		Flickable {
			id: stylesFlickable
			
			clip: true
			boundsBehavior: Flickable.OvershootBounds
			
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			width: parent.width
			contentWidth: parent.width
			contentHeight: settingsColumn.height
			
			ScrollBar.vertical: ScrollBar { }
			
			Column {
				id: settingsColumn
				width: parent.width
				anchors.centerIn: parent.center
				
				spacing: units.dp(20)
				
				ComboBox {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.8
					id: colorSelector
					displayText: styleModel.get(currentIndex).stext
					model: ListModel {
						id: styleModel
						ListElement {
							stext: "Black on White"
							back: "white"
							fore: "black"
							comboboxback: "white"
							comboboxfore: "black"
						}
						ListElement {
							stext: "Dark on Texture"
							back: "url(.background_paper@30.png)"
							fore: "#222"
							comboboxback: "#dddddd"
							comboboxfore: "#222222"
						}
						ListElement {
							stext: "Light on Texture"
							back: "url(.background_paper_invert@30.png)"
							fore: "#999"
							comboboxback: "#222222"
							comboboxfore: "#dddddd"
						}
						ListElement {
							stext: "White on Black"
							back: "black"
							fore: "white"
							comboboxback: "black"
							comboboxfore: "white"
						}
					}
					onCurrentIndexChanged: {
						bookStyles.textColor = styleModel.get(currentIndex).fore
						bookStyles.background = styleModel.get(currentIndex).back
					}
					delegate: ItemDelegate {
						highlighted: colorSelector.highlightedIndex === index
						width: parent.width
						contentItem: Text {
							text: stext
							color: comboboxfore
						}
						background: Rectangle {
							color: comboboxback
						}
					}
				}
				ComboBox {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.8
					id: fontSelector
					visible: !server.reader.pictureBook
					onCurrentIndexChanged: bookStyles.fontFamily = model[currentIndex]
					displayText: (model[currentIndex] == "Default") ? i18n.tr("Default Font") : model[currentIndex]
					
					model: fontLister.fontList
					
					delegate: ItemDelegate {
						highlighted: fontSelector.highlightedIndex === index
						width: parent.width
						contentItem: Text {
							text: (modelData == "Default") ? i18n.tr("Default Font") : modelData
							font.family: modelData
							color: theme.palette.normal.foregroundText
						}
					}
				}

				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.9
					visible: !server.reader.pictureBook
					Text {
						/*/ Prefer string of < 16 characters /*/
						text: i18n.tr("Font Scaling")
						color: theme.palette.normal.foregroundText
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						width: stylesDialog.labelwidth
						height: fontScaleSlider.height
					}

					Slider {
						id: fontScaleSlider
						width: parent.width - stylesDialog.labelwidth
						from: 0.5
						to: 4
						stepSize: 0.25
						snapMode: Slider.snapAlways
						onMoved: bookStyles.fontScale = value
					}
				}

				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.9
					visible: !server.reader.pictureBook
					Text {
						/*/ Prefer string of < 16 characters /*/
						text: i18n.tr("Line Height")
						color: theme.palette.normal.foregroundText
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						width: stylesDialog.labelwidth
						height: lineHeightSlider.height
					}

					Slider {
						id: lineHeightSlider
						width: parent.width - stylesDialog.labelwidth
						from: 0.8
						to: 2
						stepSize: 0.2
						snapMode: Slider.snapAlways
						onMoved: bookStyles.lineHeight = value
					}
				}

				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.9
					visible: !server.reader.pictureBook
					Text {
						/*/ Prefer string of < 16 characters /*/
						text: i18n.tr("Margins")
						color: theme.palette.normal.foregroundText
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						width: stylesDialog.labelwidth
						height: marginSlider.height
					}

					Slider {
						id: marginSlider
						width: parent.width - stylesDialog.labelwidth
						from: 0
						to: 30
						stepSize: 3
						snapMode: Slider.snapAlways
						function formatValue(v) { return Math.round(v) + "%" }
						onValueChanged: bookStyles.margin = value
					}
				}

				Button {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.8
					/*/ Prefer < 16 characters /*/
					text: i18n.tr("Make Default")
					enabled: !bookStyles.atdefault
					onClicked: bookStyles.saveAsDefault()
				}
				Button {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.8
					/*/ Prefer < 16 characters /*/
					text: i18n.tr("Load Defaults")
					enabled: !bookStyles.atdefault
					onClicked: bookStyles.resetToDefaults()
				}
				
				Button {
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width * 0.8
					text: i18n.tr("Close")
					highlighted: true
					onClicked: stylesDialog.close()
				}
			}
		}
		
		onOpened: {
			if (bookStyles.loading == false)
				setValues()
		}
			
		function setValues() {
			for (var i=0; i<styleModel.count; i++) {
				if (styleModel.get(i).fore == bookStyles.textColor) {
					colorSelector.currentIndex = i
					break
				}
			}
			fontSelector.currentIndex = fontSelector.model.indexOf(bookStyles.fontFamily)
			fontScaleSlider.value = bookStyles.fontScale
			lineHeightSlider.value = bookStyles.lineHeight
			marginSlider.value = bookStyles.margin
		}
		
		function onLoadingChanged() {
			if (bookStyles.loading == false)
				setValues()
		}

		Component.onCompleted: {
			setValues()
			bookStyles.onLoadingChanged.connect(onLoadingChanged)
		}

		Component.onDestruction: {
			bookStyles.onLoadingChanged.disconnect(onLoadingChanged)
		}
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

	function onPageChange() {
		setBookSetting("locus", {
			componentId: book_componentId,
			percent: Number(book_percent)
		})
		pageMetric.turnPage()
	}
	
    function windowSizeChanged() {
		bookLoadingStart()
		bookWebView.runJavaScript("reader.resized();")
    }

    Component.onCompleted: {
        server.reader.contentsReady.connect(parseContents)
        onWidthChanged.connect(windowSizeChanged)
        onHeightChanged.connect(windowSizeChanged)
    }
}

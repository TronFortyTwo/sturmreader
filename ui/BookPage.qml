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

import Ubuntu.Components 1.3 as UUITK
import UserMetrics 0.1 as UUITK

import FontList 1.0
import Units 1.0

import "components"
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

    header: UUITK.PageHeader {
        visible: false
    }

    focus: true
    Keys.onPressed: {
        if (event.key == Qt.Key_Right || event.key == Qt.Key_Down || event.key == Qt.Key_Space
                || event.key == Qt.Key_Period) {
			bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: 1}))");
        } else if (event.key == Qt.Key_Left || event.key == Qt.Key_Up
                   || event.key == Qt.Key_Backspace || event.key == Qt.Key_Comma) {
			bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: -1}))");
		}
        event.accepted = true
    }

    onVisibleChanged: {
        mainView.automaticOrientation = !visible
        if (visible == false) {
            // Reset things for the next time this page is opened
			isBookReady = false
			doPageChangeAsSoonAsReady = false
            if (history)
                history.clear()
            url = ""
            bookWebView.opacity = 0
            loadingIndicator.opacity = 1
            closeBottomEdge()
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
    
    
	WebEngineView {
		id: bookWebView
		anchors.fill: parent
		opacity: 0
		focus: false
		onJavaScriptConsoleMessage: function(level, msg, linen, sourceID) {
			console.log("WEB: " + msg + " | level: " + level + " | line: " + linen + " | source: " + sourceID);
		}
		onJavaScriptDialogRequested: function(request) {
			request.accepted = true;
			request.dialogAccept();
			
			console.log("got alert message: " + request.message );
			var msg = request.message.split(" ");
			
			if(msg[0] == "Jumping") {
				bookPage.onJumping([msg[1], msg[2]]);
			}
			else if(msg[0] == "PageChange") {
				if(!isBookReady)
					doPageChangeAsSoonAsReady = true;
				else
				{
					loadingIndicator.opacity = 0;
					bookWebView.opacity = 1;
					bookPage.onPageChange();
				}
			}
			else if(msg[0] == "Ready") {
				isBookReady = true;
				if(doPageChangeAsSoonAsReady) {
					bookPage.onPageChange();
					doPageChangeAsSoonAsReady = false;
				}
				bookWebView.opacity = 1;
				loadingIndicator.opacity = 0;
				previewControls();
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
			else
				console.log("error: unrecognized request message: " + request.message );
		}
		
		onActiveFocusChanged: {
			if(activeFocus)
				closeBottomEdge()
			// reject attempts to give WebView focus
			focus = false;
		}
	}

	UUITK.Metric {
		id: pageMetric
		name: "page-turn-metric"
		format: i18n.tr("Pages read today: %1")
		emptyFormat: i18n.tr("No pages read today")
		domain: mainView.applicationName
	}

    bottomEdgeControls: Rectangle {
		
		antialiasing: false
		color: "#ffffff"
		
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height

        FloatingButton {
            anchors.left: parent.left

            buttons: [
                Action {
                    iconName: "go-home"

                    onTriggered: {
                        pageStack.pop()
                        localBooks.flickable.returnToBounds()  // Fix bug #63
                    }
                }
            ]
        }

        FloatingButton {
			anchors.left: parent.horizontalCenter
			
			buttons: [
				Action {
					iconName: "go-previous"
					onTriggered: {
						bookWebView.opacity = 0;
						loadingIndicator.opacity = 1;
						bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: -10}))");
					}
				},
				Action {
					iconName: "go-next"
					onTriggered: {
						bookWebView.opacity = 0;
						loadingIndicator.opacity = 1;
						bookWebView.runJavaScript("reader.moveTo(reader.getPlace().getLocus({direction: 10}))");
					}
				}
			]
		}
		
		FloatingButton {
			anchors.right: parent.horizontalCenter

            buttons: [
                Action {
                    iconName: "undo"
                    enabled: canBack
                    onTriggered: {
                        var locus = history.goBackward()
                        if (locus !== null) {
							navjump = true;
							bookWebView.opacity = 0;
							loadingIndicator.opacity = 1;
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
							bookWebView.opacity = 0;
							loadingIndicator.opacity = 1;
							bookWebView.runJavaScript("reader.moveTo(" + locus + ")");
                        }
                    }
                }
            ]
        }

        FloatingButton {
            anchors.right: parent.right

            buttons: [
                Action {
                    iconName: "settings"
                    onTriggered: {
                        stylesDialog.open()
                        closeBottomEdge()
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
					bookWebView.runJavaScript("reader.skipToChapter(" + JSON.stringify(model.src) + ");");
					closeBottomEdge()
				}
            }

            Connections {
                target: bookPage
                onBottomEdgePressed: {
                    for (var i=0; i<contentsListModel.count; i++) {
                        if (contentsListModel.get(i).src == bookPage.currentChapter)
							contentsListView.positionViewAtIndex(i, ListView.Center)
                    }
                }
            }
            ScrollBar.vertical: ScrollBar {}
        }
    }
    bottomEdgeTitle: i18n.tr("Contents")
    reloadBottomEdgePage: false

    Item {
        id: bookStyles
        property bool loading: false
        property bool atdefault: false

        property string textColor
        property string fontFamily
        property var lineHeight
        property real fontScale
        property string background
        property real margin
        property real marginv
        property real bumper

        property var defaults: ({
            textColor: "#222",
            fontFamily: "Default",
            lineHeight: "Default",
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
		property real labelwidth: width * 0.5
		
		width: parent.width * 0.75
		height: parent.height * 0.5
		leftMargin: (parent.width - width) * 0.5
		topMargin: (parent.height - height) * 0.5
		ColumnLayout {
			width: parent.width
			height: parent.height
			spacing: units.dp(2)
			ComboBox {
				width: parent.width * 0.6
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
				width: parent.width * 0.6
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
				width: parent.width * 0.9
				visible: !server.reader.pictureBook
				Text {
					/*/ Prefer string of < 16 characters /*/
					text: i18n.tr("Font Scaling")
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
					onValueChanged: bookStyles.fontScale = value
				}
			}

			Row {
				width: parent.width * 0.9
				visible: !server.reader.pictureBook
				Text {
					/*/ Prefer string of < 16 characters /*/
					text: i18n.tr("Line Height")
					verticalAlignment: Text.AlignVCenter
					wrapMode: Text.Wrap
					width: stylesDialog.labelwidth
					height: lineHeightSlider.height
				}

				UUITK.Slider {
					id: lineHeightSlider
					width: parent.width - stylesDialog.labelwidth
					minimumValue: 0.8
					maximumValue: 2
					// If we make this a color, instead of a string, it stays linked to the
					// property, instead of storing the old value.  Moreover, we can't set it
					// here, for reasons I don't understand.  So we wait....
					property string activeColor: ""

					function formatValue(v, untranslated) {
						if (v < 0.95)
							/*/ Indicates the default line height will be used, as opposed to a /*/
							/*/ user-set value.  There is only space for about 5 characters; if /*/
							/*/ the translated string will not fit, please translate this as an /*/
							/*/ em-dash (—). /*/
							return untranslated ? "Default" : i18n.tr("Auto")
						return v.toFixed(1)
					}
					function setThumbColor() {
						if (activeColor === "")
							activeColor = __styleInstance.thumb.color

						__styleInstance.thumb.color = (value < 0.95) ?
									UbuntuColors.warmGrey : activeColor
					}
					onValueChanged: {
						bookStyles.lineHeight = formatValue(value, true)
						setThumbColor()
					}
					onPressedChanged: {
						if (pressed)
							__styleInstance.thumb.color = activeColor
						else
							setThumbColor()
					}
				}
			}

			Row {
				width: parent.width * 0.9
				visible: !server.reader.pictureBook
				Text {
					/*/ Prefer string of < 16 characters /*/
					text: i18n.tr("Margins")
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
					function formatValue(v) { return Math.round(v) + "%" }
					onValueChanged: bookStyles.margin = value
				}
			}

			Button {
				width: parent.width * 0.8
				text: i18n.tr("Close")
				highlighted: true
				onClicked: stylesDialog.close()
			}

			GridLayout {
				Button {
					id: setDefault
					/*/ Prefer string of < 16 characters /*/
					text: i18n.tr("Make Default")
					width: units.dp(100)
					anchors {
						left: parent.left
						top: parent.top
						//width: parent.width / 2
					}
					enabled: !bookStyles.atdefault
					onClicked: bookStyles.saveAsDefault()
				}
				Button {
					id: loadDefault
					/*/ Prefer string of < 16 characters /*/
					text: i18n.tr("Load Defaults")
					width: units.dp(100)
					anchors {
						right: parent.right
						bottom: parent.bottom
					}
					enabled: !bookStyles.atdefault
					onClicked: bookStyles.resetToDefaults()
				}
			}

			function setValues() {
				for (var i=0; i<styleModel.count; i++) {
					if (styleModel.get(i).fore == bookStyles.textColor) {
						colorSelector.currentIndex = i
						break
					}
				}
				fontSelector.currentIndex = fontSelector.model.indexOf(bookStyles.fontFamily)
				//fontScaleSlider.value = 4 + 4 * Math.LOG2E * Math.log(bookStyles.fontScale)
				fontScaleSlider.value = bookStyles.fontScale
				lineHeightSlider.value = (bookStyles.lineHeight == "Default") ? 0.8 : bookStyles.lineHeight
				marginSlider.value = bookStyles.margin
			}
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
		pageMetric.increment()
	}

    function windowSizeChanged() {
		bookWebView.runJavaScript("reader.resized();");
    }

    Component.onCompleted: {
        server.reader.contentsReady.connect(parseContents)
        onWidthChanged.connect(windowSizeChanged)
        onHeightChanged.connect(windowSizeChanged)
    }
}

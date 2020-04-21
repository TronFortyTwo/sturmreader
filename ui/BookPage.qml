/* Copyright 2013-2015 Robert Schroll
 * Copyright 2020 Emanuele Sorce - emanuele.sorce@hotmail.com
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.7
import UserMetrics 0.1
import FontList 1.0

import "components"
import "historystack.js" as History


PageWithBottomEdge {
    id: bookPage
    //flickable: null

    property alias url: bookWebView.url
    property var currentChapter: null
    property var history: new History.History(updateNavButtons)
    property bool navjump: false
    property bool canBack: false
    property bool canForward: false
    property bool isBookReady: false
    property bool doPageChangeAsSoonAsReady: false

    header: PageHeader {
        visible: false
    }

    focus: true
    Keys.onPressed: {
        if (event.key == Qt.Key_Right || event.key == Qt.Key_Down || event.key == Qt.Key_Space
                || event.key == Qt.Key_Period) {
			//Messaging.sendMessage("ChangePage", 1)
			bookWebView.runJavaScript("reader.moveTo({direction: '1'});");
            event.accepted = true
        } else if (event.key == Qt.Key_Left || event.key == Qt.Key_Up
                   || event.key == Qt.Key_Backspace || event.key == Qt.Key_Comma) {
            //Messaging.sendMessage("ChangePage", -1)
			bookWebView.runJavaScript("reader.moveTo({direction: '-1'});");
			event.accepted = true
        }
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

    ActivityIndicator {
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
			console.log("got alert message: " + request.message );
			var msg = request.message.split(" ");
			
			if(msg[0] == "Jumping") {
				bookPage.onJumping([msg[1], msg[2]]);
			}
			else if(msg[0] == "PageChange") {
				if(!isBookReady)
					doPageChangeAsSoonAsReady = true;
				else
					bookPage.onPageChange();
			}
			else if(msg[0] == "Ready") {
				bookPage.onReady();
				isBookReady = true;
				if(doPageChangeAsSoonAsReady) {
					bookPage.onPageChange();
					doPageChangeAsSoonAsReady = false;
				}
			}
			else
				console.log("error: unrecognized request message: " + request.message );
			request.accepted = true;
			request.dialogAccept();
		}
		//url: filesystem.getDataDir("")
		//onTitleChanged: function() {
		//	console.log('title changed: ' + title);
		//}
		
		onActiveFocusChanged: {
			if(activeFocus)
				closeBottomEdge()
			// reject attempts to give WebView focus
			focus = false;
		}
	}

    Metric {
        id: pageMetric
        name: "page-turn-metric"
        format: i18n.tr("Pages read today: %1")
        emptyFormat: i18n.tr("No pages read today")
        domain: mainView.applicationName
    }

    bottomEdgeControls: Item {
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height

        FloatingButton {
            anchors.left: parent.left

            buttons: [
                Action {
                    iconName: "back"

                    onTriggered: {
                        pageStack.pop()
                        localBooks.flickable.returnToBounds()  // Fix bug #63
                    }
                }
            ]
        }

        FloatingButton {
            anchors.horizontalCenter: parent.horizontalCenter

            buttons: [
                Action {
                    iconName: "go-previous"
                    enabled: canBack
                    onTriggered: {
                        var locus = history.goBackward()
                        if (locus !== null) {
                            navjump = true;
                            //Messaging.sendMessage("GotoLocus", locus)
							bookWebView.runJavaScript("reader.moveTo(" + locus + ")");
                        }
                    }
                },
                Action {
                    iconName: "go-next"
                    enabled: canForward
                    onTriggered: {
                        var locus = history.goForward()
                        if (locus !== null) {
							navjump = true;
							//Messaging.sendMessage("GotoLocus", locus)
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
                        PopupUtils.open(stylesComponent)
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
            delegate: Standard {
                text: (new Array(model.level + 1)).join("    ") +
                      model.title.replace(/(\n| )+/g, " ").replace(/^%PAGE%/, i18n.tr("Page"))
                selected: bookPage.currentChapter == model.src
				onClicked: {
					//Messaging.sendMessage("NavigateChapter", model.src)
					bookWebView.runJavaScript("reader.skipToChapter(" + JSON.stringify(model.src) + ");");
					closeBottomEdge()
				}
            }

            Connections {
                target: bookPage
                onBottomEdgePressed: {
                    for (var i=0; i<contentsListModel.count; i++) {
                        if (contentsListModel.get(i).src == bookPage.currentChapter)
                            positionViewAtIndex(i, ListView.Center)
                    }
                }
            }
        }
        Scrollbar {
            flickableItem: contentsListView
            align: Qt.AlignTrailing
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
            var widthgu = width/units.gu(1)
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

    Component {
        id: stylesComponent

        Dialog {
            id: stylesDialog
            property real labelwidth: units.gu(11)

            OptionSelector {
                id: colorSelector
                onSelectedIndexChanged: {
                    bookStyles.textColor = model.get(selectedIndex).foreground
                    bookStyles.background = model.get(selectedIndex).background
                }
                model: colorModel

                delegate: StylableOptionSelectorDelegate {
					text: server.reader.pictureBook ? pictureName : i18n.tr(name)
                    Component.onCompleted: {
                        textLabel.color = foreground
                        if (background.slice(0, 5) == "url(.") {
                            var filename = Qt.resolvedUrl("../html/" + background.slice(5, -1))
                            backgroundImage.source = filename
                        } else {
                            backgroundShape.color = background
                        }
                    }

                    UbuntuShape {
                        id: backgroundShape
                        anchors {
                            leftMargin: units.gu(0)
                            rightMargin: units.gu(0)
                            fill: parent
                        }
                        z: -1
                        image: Image {
                            id: backgroundImage
                            fillMode: Image.Tile
                        }
                    }
                }
            }

            ListModel {
                id: colorModel
                ListElement {
					name: "Black on White"
                    pictureName: "White"
                    foreground: "black"
                    background: "white"
                }
                ListElement {
					name: "Dark on Texture"
                    pictureName: "Light Texture"
                    foreground: "#222"
                    background: "url(.background_paper@30.png)"
                }
                ListElement {
					name: "Light on Texture"
                    pictureName: "Dark Texture"
                    foreground: "#999"
                    background: "url(.background_paper_invert@30.png)"
                }
                ListElement {
					name: "White on Black"
                    pictureName: "Black"
                    foreground: "white"
                    background: "black"
                }
            }

            OptionSelector {
                id: fontSelector
                visible: !server.reader.pictureBook
                onSelectedIndexChanged: bookStyles.fontFamily = model[selectedIndex]

                model: fontLister.fontList

                delegate: StylableOptionSelectorDelegate {
                    text: (modelData == "Default") ? i18n.tr("Default Font") : modelData
                    Component.onCompleted: {
                        if (modelData != "Default")
                            textLabel.font.family = modelData
                    }
                }
            }

            Row {
                visible: !server.reader.pictureBook
                Label {
                    /*/ Prefer string of < 16 characters /*/
                    text: i18n.tr("Font Scaling")
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    width: labelwidth
                    height: fontScaleSlider.height
                }

                Slider {
                    id: fontScaleSlider
                    width: parent.width - labelwidth
                    minimumValue: 0
                    maximumValue: 12
                    function formatValue(v) {
                        return ["0.5", "0.59", "0.7", "0.84", "1", "1.2", "1.4", "1.7", "2", "2.4",
                                "2.8", "3.4", "4"][Math.round(v)]
                    }
                    onValueChanged: bookStyles.fontScale = formatValue(value)
                }
            }

            Row {
                visible: !server.reader.pictureBook
                Label {
                    /*/ Prefer string of < 16 characters /*/
                    text: i18n.tr("Line Height")
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    width: labelwidth
                    height: lineHeightSlider.height
                }

                Slider {
                    id: lineHeightSlider
                    width: parent.width - labelwidth
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
                visible: !server.reader.pictureBook
                Label {
                    /*/ Prefer string of < 16 characters /*/
                    text: i18n.tr("Margins")
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    width: labelwidth
                    height: marginSlider.height
                }

                Slider {
                    id: marginSlider
                    width: parent.width - labelwidth
                    minimumValue: 0
                    maximumValue: 30
                    function formatValue(v) { return Math.round(v) + "%" }
                    onValueChanged: bookStyles.margin = value
                }
            }

            StyledButton {
                text: i18n.tr("Close")
                onClicked: PopupUtils.close(stylesDialog)
            }

            Item {
                property bool horizontal: (setDefault.text.length < 16 && loadDefault.text.length < 16)
                height: horizontal ? setDefault.height : 2 * setDefault.height + units.gu(2)
                StyledButton {
                    id: setDefault
                    /*/ Prefer string of < 16 characters /*/
                    text: i18n.tr("Make Default")
                    width: parent.horizontal ? parent.width/2 - units.gu(1) : parent.width
                    anchors {
                        left: parent.left
                        top: parent.top
                        //width: parent.width / 2
                    }
                    primary: false
                    enabled: !bookStyles.atdefault
                    onClicked: bookStyles.saveAsDefault()
                }
                StyledButton {
                    id: loadDefault
                    /*/ Prefer string of < 16 characters /*/
                    text: i18n.tr("Load Defaults")
                    width: parent.horizontal ? parent.width/2 - units.gu(1) : parent.width
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    primary: false
                    enabled: !bookStyles.atdefault
                    onClicked: bookStyles.resetToDefaults()
                }
            }

            function setValues() {
                for (var i=0; i<colorModel.count; i++) {
                    if (colorModel.get(i).foreground == bookStyles.textColor) {
                        colorSelector.selectedIndex = i
                        break
                    }
                }
                fontSelector.selectedIndex = fontSelector.model.indexOf(bookStyles.fontFamily)
                fontScaleSlider.value = 4 + 4 * Math.LOG2E * Math.log(bookStyles.fontScale)
                lineHeightSlider.value = (bookStyles.lineHeight == "Default") ? 0.8 : bookStyles.lineHeight
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
		currentChapter = bookWebView.runJavaScript("reader.getPlace().chapterSrc()");
		setBookSetting("locus", {
			componentId: bookWebView.runJavaScript("reader.getPlace().componentId()"),
			percent: Number(bookWebView.runJavaScript("reader.getPlace().percentageThrough()"))
		})
		pageMetric.increment()
	}

    function onReady() {
        bookWebView.opacity = 1;
        loadingIndicator.opacity = 0;
        previewControls();
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

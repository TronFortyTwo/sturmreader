/* Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick.Controls 2.2
import QtQuick 2.9
import QtQuick.Layouts 1.3

Page {
	header: ToolBar {
		id: aboutheader
		width: parent.width
		RowLayout {
			spacing: scaling.dp(10)
			anchors.fill: parent
			
			ToolButton {
				padding: scaling.dp(7)
				contentItem: Icon {
					anchors.centerIn: parent
					name: "go-previous"
					color: colors.item
				}
				onClicked: pageStack.pop()
			}
			
			Label {
				text: gettext.tr("About")
				font.pixelSize: scaling.dp(22)
				elide: Label.ElideRight
				horizontalAlignment: Qt.AlignLeft
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
		}
	}
	
	Flickable {
		id: flickable
		anchors.fill: parent
		contentHeight:  layout.height + scaling.dp(80)
		contentWidth: parent.width
		ScrollBar.vertical: ScrollBar { }
		
		Column {
			id: layout

			spacing: 42
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			width: parent.width
			
			Item {
				height: scaling.dp(30)
			}
			
			Image {
				anchors.horizontalCenter: parent.horizontalCenter
				height: width
				width: Math.min(parent.width/2, parent.height/3)
				source: Qt.resolvedUrl("../../sturmreader.svg")
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				font.pointSize: 30
				font.bold: true
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				text: gettext.tr("Sturm Reader")
				color: colors.text
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: colors.text
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: gettext.tr("Sturm (und Drang) Reader is an open source Ebook reader.<br>Community is what makes this app possible, so pull requests, translations, feedback and donations are very appreciated :)<br>This app Is a fork of the Beru app by Rshcroll, Thanks!<br>This app stands on the shoulder of various Open Source projects, see source code for licensing details");
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: colors.text
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: gettext.tr("A big thanks to all translators, beta-testers, and users<br/>in general who improve this app with their work and feedback")
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: colors.text
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: gettext.tr("A special thanks to Joan Cibersheep for the new logo")
			}
					
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: colors.text
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: gettext.tr("A special thanks to Jeroen for support and a test device")
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: gettext.tr("See source on Github")
				highlighted: true
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://github.com/tronfortytwo/sturmreader");
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: gettext.tr("Report bug or feature request")
				highlighted: true
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://github.com/tronfortytwo/sturmreader/issues");
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: gettext.tr("See License (GNU GPL v3)")
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://github.com/TronFortyTwo/sturmreader/blob/master/LICENSE");
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: gettext.tr("❤Donate❤")
				highlighted: true
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://paypal.me/emanuele42");
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: colors.text
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: "Copyright (C) 2018-2020 Emanuele Sorce (emanuele.sorce@hotmail.com)"

			}
				
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: colors.text
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: "Copyright (C) 2015 Robert Schroll"
			}
		}
	}
}

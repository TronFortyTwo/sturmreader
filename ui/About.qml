/* Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick.Controls 2.2
import QtQuick 2.9
import QtQuick.Layouts 1.3

import "components"

import Units 1.0

Page {
	id: bookSources
	title: i18n.tr("About")
	
	header: ToolBar {
		id: aboutheader
		width: parent.width
		RowLayout {
			spacing: units.dp(10)
			anchors.fill: parent
			
			ToolButton {
				padding: units.dp(8)
				contentItem: Icon {
					anchors.centerIn: parent
					name: "go-previous"
					color: theme.palette.normal.baseText
				}
				onClicked: pageStack.pop()
			}
			
			Label {
				text: i18n.tr("About")
				font.pixelSize: units.dp(22)
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
		contentHeight:  layout.height + units.dp(80)
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
				height: units.dp(30)
			}
			
			Image {
				anchors.horizontalCenter: parent.horizontalCenter
				height: width
				width: Math.min(parent.width/2, parent.height/3)
				source: Qt.resolvedUrl("../sturmreader.svg")
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				font.pointSize: 30
				font.bold: true
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				text: i18n.tr("Sturm Reader")
				color: theme.palette.normal.baseText
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: theme.palette.normal.baseText
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("Sturm (und Drang) Reader is an open source Ebook reader.<br>Community is what makes this app possible, so pull requests, translations, feedback and donations are very appreciated :)<br>This app Is a fork of the Beru app by Rshcroll, Thanks!<br>This app stands on the shoulder of various Open Source projects, see source code for licensing details");
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: theme.palette.normal.baseText
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("A big thanks to all translators, beta-testers, and users<br/>in general who improve this app with their work and feedback")
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: theme.palette.normal.baseText
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("A special thanks to Joan Cibersheep for the new logo")
			}
					
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: theme.palette.normal.baseText
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("A special thanks to Jeroen for support and a test device")
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: i18n.tr("See source on Github")
				highlighted: true
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://github.com/tronfortytwo/sturmreader");
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: i18n.tr("Report bug or feature request")
				highlighted: true
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://github.com/tronfortytwo/sturmreader/issues");
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: i18n.tr("See License (GNU GPL v3)")
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://github.com/TronFortyTwo/sturmreader/blob/master/LICENSE");
			}
			
			Button {
				anchors.horizontalCenter: parent.horizontalCenter
				text: i18n.tr("❤Donate❤")
				highlighted: true
				width: parent.width * 4 / 5
				onClicked: Qt.openUrlExternally("https://paypal.me/emanuele42");
			}
			
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: theme.palette.normal.baseText
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: "Copyright (C) 2018-2020 Emanuele Sorce (emanuele.sorce@hotmail.com)"

			}
				
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width * 4 / 5
				color: theme.palette.normal.baseText
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: "Copyright (C) 2015 Robert Schroll"
			}
		}
	}
}

/* Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import "components"
import Ubuntu.Components.ListItems 1.3

Page {
	id: bookSources
	title: i18n.tr("About")
	
	Flickable {
		id: flickable
		anchors.fill: parent
		contentHeight: layout.height + units.gu(10)
			
		Column {
			id: layout

			spacing: units.gu(3)
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
				
			UbuntuShape {
				anchors.horizontalCenter: parent.horizontalCenter
				height: width
				width: Math.min(parent.width/2, parent.height/2)
				source: Image {
					source: Qt.resolvedUrl("../sturmreader.svg")
				}
				radius: "large"
			}
			
			Label {
				width: parent.width
				textSize: Label.XLarge
				font.weight: Font.DemiBold
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				text: i18n.tr("Sturm Reader")
			}
			
			Label {
				width: parent.width
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("Sturm (und Drang) Reader is an open source Ebook reader.<br>Community is what makes this app possible, so pull requests, translations, feedback and donations are very appreciated :)<br>This app Is a fork of the Beru app by Rshcroll, Thanks!<br>This app stands on the shoulder of various Open Source projects, see source code for licensing details");
			}
			
			Label {
				width: parent.width
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("A big thanks to all translators, beta-testers, and users<br/>in general who improve this app with their work and feedback")
			}
			
			Label {
				width: parent.width
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("A special thanks to Joan Cibersheep for the new logo")
			}
					
			Label {
				width: parent.width
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: i18n.tr("A special thanks to Jeroen for support and a test device")
			}
			
			Button {
				text: i18n.tr("See source on Github")
				color: UbuntuColors.green
				width: parent.width
				onClicked: Qt.openUrlExternally("https://github.com/tronfortytwo/sturmreader");
			}
			
			Button {
				text: i18n.tr("Report bug or feature request")
				color: UbuntuColors.green
				width: parent.width
				onClicked: Qt.openUrlExternally("https://github.com/tronfortytwo/sturmreader/issues");
			}
			
			Button {
				text: i18n.tr("See License (GNU GPL v3)")
				color: UbuntuColors.porcelain
				width: parent.width
				onClicked: Qt.openUrlExternally("https://github.com/TronFortyTwo/sturmreader/blob/master/LICENSE");
			}
			
			Button {
				text: i18n.tr("❤Donate❤")
				color: UbuntuColors.orange
				width: parent.width
				onClicked: Qt.openUrlExternally("https://paypal.me/emanuele42");
			}
			
			Label {
				width: parent.width
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: "Copyright (C) 2018-2020 Emanuele Sorce (emanuele.sorce@hotmail.com)"

			}
				
			Label {
				width: parent.width
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignHCenter
				text: "Copyright (C) 2015 Robert Schroll"
			}
		}
	}
}

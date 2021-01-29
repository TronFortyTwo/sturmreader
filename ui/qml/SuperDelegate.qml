/* Copyright 2018-2020 Emanuele Sorce
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

//
// This is an item delegate that provides additional features such as subtitle and a leading image
//

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.3

ItemDelegate {
	
	property string image_source: ""
	property string main_text: ""
	property string sub_text: ""
	
	contentItem: Item {
		width: parent.width
		implicitHeight: superColumn.height
		Image {
			id: superImage
			visible: image_source !== ""
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			source: image_source
			height: parent.height * 0.9
			fillMode: Image.PreserveAspectFit
			asynchronous: true
			sourceSize.height: height
		}
		Column {
			id: superColumn
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: parent.left
			anchors.leftMargin: image_source === "" ? 0 : parent.height * 1.5
			anchors.right: parent.right
			spacing: scaling.dp(5)
			Label {
				width: parent.width
				text: main_text
				font.pixelSize: scaling.dp(14)
				elide: Text.ElideRight
			}
			Label {
				width: parent.width
				text: sub_text
				font.pixelSize: scaling.dp(11)
				elide: Text.ElideRight
			}
		}
	}
}

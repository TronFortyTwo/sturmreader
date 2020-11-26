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


ItemDelegate {
	
	contentItem: Item {
		width: parent.width
		implicitHeight: titleDelegateColumn.height
		Image {
			id: titleDelegateImage
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			source: model.filename == "ZZZback" ? "Icons/go-previous.svg" :
					model.cover == "ZZZnone" ? defaultCover.missingCover(model) :
					model.cover == "ZZZerror" ? "images/error_cover.svg" :
						model.cover
			height: parent.height * 0.9
			asynchronous: true
			sourceSize.height: height
			sourceSize.width: width
			//border: model.filename != "ZZZback" && model.cover != "ZZZerror"
			//visible: model.filename != "ZZZback" || !wide
		}
		Column {
			id: titleDelegateColumn
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: parent.left
			anchors.leftMargin: parent.height * 1.5
			anchors.right: parent.right
			spacing: scaling.dp(5)
			Label {
				width: parent.width
				text: model.title
				color: colors.text
				font.pointSize: 16
				elide: Text.ElideRight
			}
			Label {
				width: parent.width
				text: model.author
				color: colors.text
				font.pointSize: 13
				elide: Text.ElideRight
			}
		}
	}
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

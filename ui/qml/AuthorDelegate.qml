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
		implicitWidth: parent.width
		implicitHeight: scaling.dp(42)
		Image {
			id: authorDelegateImage
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			source: model.count > 1 ? "image://theme/contact" :
					model.filename == "ZZZback" ? "image://theme/back" :
					model.cover == "ZZZnone" ? defaultCover.missingCover(model) :
					model.cover == "ZZZerror" ? "images/error_cover.svg" :
					model.cover
			width: scaling.dp(24)
			sourceSize.height: height
			sourceSize.width: width
			//border: model.filename != "ZZZback" && model.cover != "ZZZerror"
			visible: model.filename != "ZZZback" || !wide
		}
		Column {
			height: parent.height
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: authorDelegateImage.right
			anchors.leftMargin: scaling.dp(20)
			anchors.right: parent.right
			spacing: scaling.dp(5)
			Text {
				text: model.author || gettext.tr("Unknown Author")
				color: colors.text
				font.pointSize: 16
			}
			Text {
				text: (model.count > 1) ? gettext.tr("%1 Book", "%1 Books", model.count).arg(model.count)
						: model.title
				color: colors.text
				font.pointSize: 13
			}
		}
	}
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

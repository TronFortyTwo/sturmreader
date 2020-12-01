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
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.3


Item {
	width: gridview.cellWidth
	height: gridview.cellHeight

	Item {
		id: image
		anchors.fill: parent

		Image {
			anchors {
				fill: parent
				leftMargin: gridmargin
				rightMargin: gridmargin
				topMargin: 1.5*gridmargin
				bottomMargin: 1.5*gridmargin
			}
			fillMode: Image.PreserveAspectFit
			source: {
				if (model.cover == "ZZZerror")
					return defaultCover.errorCover(model)
				if (!model.fullcover)
					return defaultCover.missingCover(model)
				return model.fullcover
			}
			sourceSize.width: width
			sourceSize.height: height
			asynchronous: true

			Label {
				x: ((model.cover == "ZZZerror") ? 0.09375 : 0.125)*parent.width
				y: 0.0625*parent.width
				width: 0.8125*parent.width
				height: parent.height/2 - 0.125*parent.width
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				wrapMode: Text.Wrap
				elide: Text.ElideRight
				color: defaultCover.textColor(model)
				style: Text.Raised
				styleColor: defaultCover.highlightColor(model, defaultCover.hue(model))
				font.family: "URW Bookman L"
				visible: !model.fullcover
				text: model.title
			}

			Label {
				x: ((model.cover == "ZZZerror") ? 0.09375 : 0.125)*parent.width
				y: parent.height/2 + 0.0625*parent.width
				width: 0.8125*parent.width
				height: parent.height/2 - 0.125*parent.width
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				wrapMode: Text.Wrap
				elide: Text.ElideRight
				color: defaultCover.textColor(model)
				style: Text.Raised
				styleColor: defaultCover.highlightColor(model, defaultCover.hue(model))
				font.family: "URW Bookman L"
				visible: !model.fullcover
				text: model.author
			}
		}
	}

	DropShadow {
		anchors.fill: image
		radius: 12
		samples: 12
		source: image
		color: Qt.tint(colors.background, "#65666666")
		verticalOffset: height * 0.025
		horizontalOffset: width * 0.025
	}

	MouseArea {
		anchors.fill: parent
		onClicked: {
			// Save copies now, since these get cleared by loadFile (somehow...)
			var filename = model.filename
			var pasterror = model.cover == "ZZZerror"
			if (loadFile(filename) && pasterror)
				refreshCover(filename)
		}
		onPressAndHold: openInfoDialog(model)
	}
} 

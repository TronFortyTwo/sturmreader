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
	property string cover
	property string fullcover
	property string title: ""
	property string author: ""
	property int coverMargin: 0
	
	Item {
		id: image
		anchors.fill: parent

		Image {
			anchors {
				fill: parent
				leftMargin: coverMargin
				rightMargin: coverMargin
				topMargin: 1.5 * coverMargin
				bottomMargin: 1.5 * coverMargin
			}
			fillMode: Image.PreserveAspectFit
			source: {
				if (cover == "ZZZerror")
					return defaultCover.errorCover()
				if (!fullcover || fullcover == "ZZZnull")
					return defaultCover.missingCover(title, cover)
				return fullcover
			}
			sourceSize.width: width
			sourceSize.height: height
			asynchronous: true

			Label {
				x: ((cover == "ZZZerror") ? 0.09375 : 0.125)*parent.width
				y: 0.0625*parent.width
				width: 0.8125*parent.width
				height: parent.height/2 - 0.125*parent.width
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				wrapMode: Text.Wrap
				elide: Text.ElideRight
				color: defaultCover.textColor(cover)
				style: Text.Raised
				styleColor: defaultCover.highlightColor(cover, defaultCover.hue(title))
				font.family: "URW Bookman L"
				font.pixelSize: parent.height * 0.075
				visible: !fullcover || fullcover == "ZZZnull"
				text: title
			}

			Label {
				x: ((cover == "ZZZerror") ? 0.09375 : 0.125)*parent.width
				y: parent.height/2 + 0.0625*parent.width
				width: 0.8125*parent.width
				height: parent.height/2 - 0.125*parent.width
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				wrapMode: Text.Wrap
				elide: Text.ElideRight
				color: defaultCover.textColor(cover)
				style: Text.Raised
				styleColor: defaultCover.highlightColor(cover, defaultCover.hue(title))
				font.family: "URW Bookman L"
				font.pixelSize: parent.height * 0.08
				visible: !fullcover || fullcover == "ZZZnull"
				text: author
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
} 

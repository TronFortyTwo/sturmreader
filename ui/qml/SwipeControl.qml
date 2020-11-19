/* Copyright 2015 Robert Schroll
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2

Rectangle {
    id: swipeControl
    color: colors.negative
    height: actionLabel.height + 2 * marginWidth
    width: parent.width
    clip: true

    property double lineWidth: scaling.dp(1)
    property double marginWidth: scaling.dp(15)
    property double threshold: 0.5
    property string actionText: ""
    property string notificationText: ""
    property color sliderColor: colors.foreground

    signal triggered

    Text {
        id: actionLabel
        text: swipeControl.actionText
        anchors {
            top: parent.top
            left: parent.left
            margins: swipeControl.marginWidth
        }
        color: swipeControl.sliderColor
        opacity: slider.x > slider.width * swipeControl.threshold
        scale: (slider.x > slider.width * swipeControl.threshold) ? 1.0 : 0.8

        Behavior on opacity {
            NumberAnimation {
                duration: 333
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 333
            }
        }
    }

    Rectangle {
        id: slider
        anchors {
            top: parent.top
            bottom: parent.bottom
            topMargin: swipeControl.lineWidth
            bottomMargin: swipeControl.lineWidth
        }
        color: swipeControl.sliderColor
        width: parent.width

        Behavior on x {
            NumberAnimation {
                duration: 100
            }
        }

        Label {
            id: notificationLabel
            anchors.centerIn: parent
            color: colors.negative
            text: swipeControl.notificationText
        }
		
		Image {
			source: "Icons/go-next.svg"
			asynchronous: true
			anchors {
				top: parent.top
				topMargin: scaling.dp(5)
				bottom: parent.bottom
				bottomMargin: scaling.dp(5)
				right: parent.right
			}
			width: height
			sourceSize.width: width
			sourceSize.height: height
		}
    }

    MouseArea {
        anchors.fill: parent
        drag {
            target: slider
            axis: Drag.XAxis
            minimumX: 0
            maximumX: slider.width
        }
        onReleased: {
            if (slider.x > slider.width * swipeControl.threshold) {
                slider.x = slider.width
                swipeControl.triggered()
				slider.x = 0
            } else {
                slider.x = 0
            }
        }
    }
}

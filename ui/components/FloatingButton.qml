/* Copyright 2015 Robert Schroll
 * Copyright 2018-2020 Emanuele Sorce
 *
 * This file is part of Beru and then Sturm Reader and is distributed under the terms of
 * the GPL license. See the file COPYING for full details.
 *
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.2

import Ubuntu.Components 1.3 as UUITK

import Units 1.0

Item {
    id: floatingButton

    property int size: units.dp(30)		//units.gu(6)
    property int margin: units.dp(5)	//units.gu(1)
    property color color: "#F7F7F7" //UbuntuColors.porcelain
    property color borderColor: "#CDCDCD" //UbuntuColors.silk
    property list<Action> buttons

    width: bubble.width + 2*margin
    height: bubble.height + 2*margin

    Item {
        id: container
        anchors.fill: parent

        Rectangle {
            id: bubble

            x: margin
            y: margin
            width: childrenRect.width
            height: size
            radius: size/2
            color: floatingButton.color
            border {
                color: borderColor
                width: units.dp(1)
            }

            Row {
                Repeater {
                    model: buttons

                    AbstractButton {
                        id: button
                        width: size
                        height: size
						
						onClicked: {
							modelData.triggered()
						}
						
                        Image {
                            id: icon
                            anchors {
                                verticalCenter: parent.verticalCenter
                                horizontalCenter: parent.horizontalCenter
                            }
                            width: parent.width/2
                            height: width
                            source: button.iconSource
                            opacity: button.enabled ? 1.0 : 0.5
                        }
                    }
                }
            }
        }
    }

    DropShadow {
        anchors.fill: container
        radius: 1.5*margin
        samples: 16
        source: container
        color: borderColor
        verticalOffset: 0.25*margin
    }
}

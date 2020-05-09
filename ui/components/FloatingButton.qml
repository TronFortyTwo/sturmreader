/* Copyright 2015 Robert Schroll
 * Copyright 2018 Emanuele Sorce
 *
 * This file is part of Beru and then Sturm Reader and is distributed under the terms of
 * the GPL license. See the file COPYING for full details.
 *
 *
 */

import QtQuick 2.9
import QtGraphicalEffects 1.0
import Ubuntu.Components 1.3


Item {
    id: floatingButton

    property int size: units.gu(6)
    property int margin: units.gu(1)
    property color color: UbuntuColors.porcelain
    property color borderColor: UbuntuColors.silk
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
                        action: modelData

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

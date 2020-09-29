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

import Units 1.0

Item {
    id: floatingButton

    property real margin_to_size_ratio: 0.1
    
    // the size recommended for the button
    property int best_size: units.dp(45)
	// the size of the margin
    property int margin: size * margin_to_size_ratio
    // the maximum size allowed for the component
	property int max_size: units.dp(100)
	// the button size
	property int size: Math.min(best_size, max_size / (1 + 2*margin_to_size_ratio))
    
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
            color: Theme.palette.normal.overlay
            border {
                color: Theme.palette.normal.base
                width: units.dp(1)
            }

            Row {
                Repeater {
                    model: buttons

                    AbstractButton {
                        id: button
                        width: size
                        height: size
						
						onClicked: modelData.triggered()
						
						Icon {
							anchors {
								verticalCenter: parent.verticalCenter
								horizontalCenter: parent.horizontalCenter
							}
							width: parent.width * 0.6
							height: parent.height * 0.6
							color: Theme.palette.normal.overlayText
							name: modelData.iconName
							opacity: modelData.enabled ? 1.0 : 0.35
						}
                    }
                }
            }
        }
    }
}

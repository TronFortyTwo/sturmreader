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
import QtQuick.Controls 2.12


Item {
    id: floatingButton

    property real margin_to_size_ratio: 0.1
    
    // the size recommended for the button
    property int best_size: scaling.dp(55)
	// the size of the margin
    property int margin: size * margin_to_size_ratio
    // the maximum size allowed for the component
	property int max_size: scaling.dp(100)
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
            color: colors.overlay
            border {
                color: colors.itemDetail
                width: scaling.dp(1)
            }

            Row {
                Repeater {
                    model: buttons

                    AbstractButton {
                        id: button
                        width: size
                        height: size
						
						action: modelData
						
						Icon {
							anchors.verticalCenter: parent.verticalCenter
							anchors.horizontalCenter: parent.horizontalCenter
							
							width: parent.width * 0.6
							height: parent.height * 0.6
							
							name: modelData.icon.name
							color: colors.item
							
							opacity: modelData.enabled ? 1.0 : 0.35
						}
                    }
                }
            }
        }
    }
}

/*
 * Copyright 2020 Emanuele Sorce
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Units 1.0

Page {
    id: page

    property alias bottomEdgePageComponent: edgeLoader.sourceComponent
    property alias bottomEdgeControls: controlLoader.sourceComponent

    property int _areaWhenExpanded: 0

    signal bottomEdgePressed()
    signal bottomEdgeReleased()
    signal bottomEdgeDismissed()

	function openContent() {
		drawer.open()
	}
    function closeContent() {
        drawer.close()
    }
	function closeControls() {
		controls.close()
	}
	function openControls() {
		controls.open()
	}

    function _pushPage()
    {
        if (edgeLoader.status === Loader.Ready) {
            if (edgeLoader.item.flickable) {
                edgeLoader.item.flickable.contentY = -page.header.height
                edgeLoader.item.flickable.returnToBounds()
            }
            if (edgeLoader.item.ready)
                edgeLoader.item.ready()
        }
    }

    Dialog {
		id: drawer
		width: Math.min(parent.width, units.gu(1000))
		height: parent.height * 0.75
		y: (parent.height - height) * 0.5
		x: (parent.width - width) * 0.5
		dim: true
		
		header: ToolBar {
			width: parent.width
			RowLayout {
				anchors.fill: parent
				Label {
					text: i18n.tr("Contents")
					font.pixelSize: units.dp(27)
					color: theme.palette.normal.backgroundText
					elide: Label.ElideRight
					horizontalAlignment: Qt.AlignHCenter
					verticalAlignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}
			}
		}
		
		standardButtons: Dialog.Cancel
		
		Loader {
            id: edgeLoader
            asynchronous: true
            anchors.fill: parent
        }
	}

	Drawer {
		id: controls
		width: parent.width
		height: controlLoader.height
		z: 1
		edge: Qt.BottomEdge
		dim: false
		
		Loader {
            id: controlLoader
            asynchronous: true
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }
	}
}

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

	property alias outlineComponent: outlineLoader.sourceComponent
	property alias pagesComponent: pagesLoader.sourceComponent
	property alias bottomEdgeControls: controlLoader.sourceComponent
    
    signal contentOpened()

	function openContent() {
		content.open();
		contentOpened();
	}
    function closeContent() {
        content.close();
    }
	function closeControls() {
		controls.close();
	}
	function openControls() {
		controls.open();
	}
	function turnControlsOn() {
		controls.interactive = true;
	}
	function turnControlsOff() {
		controls.interactive = false;
	}

    Dialog {
		id: content
		width: Math.min(parent.width, units.dp(750))
		height: Math.max(parent.height * 0.75, Math.min(parent.height, units.dp(500)))
		y: (parent.height - height) * 0.5
		x: (parent.width - width) * 0.5
		dim: true
		
		header: Column {
			width: parent.width
			ToolBar {
				width: parent.width
				RowLayout {
					anchors.fill: parent
					Label {
						text: gettext.tr("Contents")
						font.pixelSize: units.dp(27)
						color: theme.palette.normal.backgroundText
						elide: Label.ElideRight
						horizontalAlignment: Qt.AlignHCenter
						verticalAlignment: Qt.AlignVCenter
						Layout.fillWidth: true
					}
				}
			}
			TabBar {
				id: sorttabs
				width: parent.width
				TabButton {
					text: gettext.tr("Outline")
					onClicked: {
						pagesLoader.visible = false;
						outlineLoader.visible = true;
					}
				}
				TabButton {
					text: gettext.tr("Pages")
					visible: server.reader.pictureBook
					onClicked: {
						outlineLoader.visible = false;
						pagesLoader.visible = true;
					}
				}
			}
		}
		
		standardButtons: Dialog.Cancel
		
		Loader {
			id: outlineLoader
			asynchronous: true
			anchors.fill: parent
		}
		
		Loader {
			visible: false
			id: pagesLoader
			asynchronous: true
			anchors.fill: parent
		}
	}

	Drawer {
		id: controls
		width: parent.width
		height: controlLoader.height
		edge: Qt.BottomEdge
		modal: false
		
		// is turned on by turnControlsOn()
		interactive: false
		
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

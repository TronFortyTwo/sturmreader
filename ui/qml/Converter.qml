/* Copyright 2021 Emanuele Sorce - emanuele.sorce@hotmail.com
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

// This dialog appears when we have to convert a file in our library
Page {
	id: convertDialog
	
	property string original_filename: ""
	property string converted_filename: ""
	
	header: ToolBar {
		width: parent.width
		RowLayout {
			spacing: scaling.dp(2)
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			
			ToolButton {
				padding: scaling.dp(7)
				contentItem: Icon {
					anchors.centerIn: parent
					name: "go-previous"
					color: colors.item
				}
				onClicked: pageStack.pop();
			}
			
			Label {
				width: parent.width
				anchors.verticalCenter: parent.verticalCenter
				text: gettext.tr("Conversion required")
				font.pixelSize: headerTextSize()
				wrapMode: Text.Wrap
				horizontalAlignment: Qt.AlignHCenter
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
			}
		}
	}
	
	Timer {
		id: convertTimer
		interval: 15
		repeat: false
		running: false
		triggeredOnStart: false
		
		onTriggered: {
			// as by now, CBZ to PDF is the only conversion possible
			var success = filesystem.convertCbz2Pdf(convertDialog.original_filename, convertDialog.converted_filename);
			if(success) {
				localBooks.addFile(convertDialog.converted_filename, true);
				pageStack.pop();
			} else {
				conversionError.visible = true;
				conversionButton.visible = false;
				converting_indicator.visible = false;
			}
		}
	}
	
	Column {
		width: parent.width
		anchors.verticalCenter: parent.verticalCenter
		spacing: scaling.dp(5);
		Label {
			width: parent.width * 0.8
			anchors.horizontalCenter: parent.horizontalCenter
			text: gettext.tr("The file that you tried to open needs to be converted to a format supported by Sturm Reader to be opened.") + '\n' +
				gettext.tr("This process is automatic and the book will be then available in your library.") + '\n' +
				gettext.tr("Press the button to start the process");
			wrapMode: Text.Wrap
		}
		
		BusyIndicator {
			id: converting_indicator
			width: scaling.dp(50)
			height: scaling.dp(50)
			anchors.horizontalCenter: parent.horizontalCenter
			running: false
		}
		
		Button {
			id: conversionButton
			/* As in convert ebook format (e.g. CBZ to PDF) */
			text: gettext.tr("Convert")
			width: parent.width * 0.7
			anchors.horizontalCenter: parent.horizontalCenter
			onClicked: {
				converting_indicator.running = true;
				
				convertTimer.start();
			}
		}
		
		Label {
			id: conversionError
			width: parent.width * 0.7
			visible: false
			anchors.horizontalCenter: parent.horizontalCenter
			color: colors.negative
			wrapMode: Text.Wrap
			text: gettext.tr("Conversion failed: you can try importing the book again. You may check the logs for more details, or open an issue for support");
		}
	}
}

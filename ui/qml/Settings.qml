/* Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */
import QtQuick.Controls 2.2
import QtQuick 2.9
import QtQuick.Layouts 1.3

Page {
	
	id: settings
	property string homepath: filesystem.homePath() + "/"
	
	header: ToolBar {
		id: aboutheader
		width: parent.width
		RowLayout {
			spacing: scaling.dp(10)
			anchors.fill: parent
			
			ToolButton {
				padding: scaling.dp(7)
				contentItem: Icon {
					anchors.centerIn: parent
					name: "go-previous"
					color: colors.item
				}
				onClicked: pageStack.pop()
			}
			
			Label {
				text: gettext.tr("Settings")
				font.pixelSize: headerTextSize()
				elide: Label.ElideRight
				horizontalAlignment: Qt.AlignLeft
				verticalAlignment: Qt.AlignVCenter
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
		}
	}
	
	Flickable {
		id: flickable
		anchors.fill: parent
		contentHeight:  settingsColumn.height + scaling.dp(80)
		contentWidth: parent.width
		ScrollBar.vertical: ScrollBar { }
		
		Column {
			id: settingsColumn
			width: parent.width
			
			// APPARMOR
			ItemDelegate {
				visible: true //!localBooks.readablehome
				width: parent.width
				contentItem: Column {
					width: parent.width
					spacing: scaling.dp(5)
					Label {
						width: parent.width
						text: gettext.tr("Default Book Location")
					}
					Label {
						width: parent.width
						text: gettext.tr("Sturm Reader seems to be operating under AppArmor restrictions that prevent it " +
							"from accessing most of your home directory.  Ebooks should be put in " +
							"<i>%1</i> for Sturm Reader to read them.").arg(localBooks.bookdir)
						wrapMode: Text.Wrap
					}
					Button {
						width: parent.width * 0.95
						anchors.horizontalCenter: parent.horizontalCenter
						text: gettext.tr("Reload Directory")
						// We don't bother with the Timer trick here since we don't get this dialog on
						// first launch, so we shouldn't have too many books added to the library when
						// this button is clicked.
						onClicked: localBooks.readBookDir()
					}
				}
			}
			
			// NOT APPARMOR (Not stable yet, more testing is needed before enabling it)
			ItemDelegate {
				visible: false//localBooks.readablehome
				width: parent.width
				
				contentItem: Column {
					width: parent.width
					spacing: scaling.dp(5)
					Label {
						width: parent.width
						text: gettext.tr("Default Book Location")
					}
					Label {
						width: parent.width
						text: gettext.tr("Enter the folder in your home directory where your ebooks are or " +
									"should be stored. Changing this value will not affect existing " +
									"books in your library.")
						wrapMode: Text.Wrap
					}
					TextField {
						id: pathfield
						anchors.horizontalCenter: parent.horizontalCenter
						width: parent.width * 0.95
						text: localBooks.bookdir
						onTextChanged: {
							var status = filesystem.exists(pathfield.text);
							if (status == 0) {
								/*/ Create a new directory from path given. /*/
								useButton.text = gettext.tr("Create Directory");
								useButton.enabled = true;
							} else if (status == 1) {
								/*/ File exists with path given. /*/
								useButton.text = gettext.tr("File Exists");
								useButton.enabled = false;
							} else if (status == 2) {
								if (pathfield.text == localBooks.bookdir && !localBooks.firststart)
									/*/ Read the books in the given directory again. /*/
									useButton.text = gettext.tr("Reload Directory")
								else
									/*/ Use directory specified to store books. /*/
									useButton.text = gettext.tr("Use Directory")
								useButton.enabled = true;
							}
						}
					}
					Button {
						id: useButton
						width: parent.width * 0.95
						anchors.horizontalCenter: parent.horizontalCenter
						onClicked: {
							var status = filesystem.exists(pathfield.text)
							if (status != 1) { // Should always be true
								if (status == 0)
									filesystem.makeDir(pathfield.text)
								localBooks.setBookDir(pathfield.text)
								useButton.enabled = false
								unblocker.start()
							}
						}
					}

					Timer {
						id: unblocker
						interval: 10
						onTriggered: {
							localBooks.readBookDir()
							localBooks.firststart = false
						}
					}
				}
			}
			/*
			SwitchDelegate {
				width: parent.width
				text: gettext.tr("Use legacy PDF viewer")
				
				onClicked: appsettings.legacypdf = checked
				Component.onCompleted: checked = appsettings.legacypdf
			}
			*/
			ItemDelegate {
				width: parent.width
				contentItem: RowLayout {
					spacing: scaling.dp(50)
					Column {
						spacing: scaling.dp(4)
						Label {
							text: gettext.tr("Application Style (experimental)")
							elide: Text.ElideRight
						}
						Label {
							text: gettext.tr("Supported styles: ") + "Suru, Material"
							elide: Text.ElideRight
						}
						Label {
							id: restartNotice
							text: gettext.tr("Requires a restart to take effect")
							elide: Text.ElideRight
							color: colors.negative
						}
					}
					ComboBox {
						Layout.alignment: Qt.AlignRight
						Layout.fillWidth: true
						model: ListModel{
							id: stylesModel
						}
						onCurrentIndexChanged: {
							styleSetting.setStyle(stylesModel.get(currentIndex).name);
						}
						
						Component.onCompleted: {
							var styles = styleSetting.availableStyles();
							var currentStyle = styleSetting.currentStyle();
							
							for(var i=0; i<styles.length; i++)
								stylesModel.append({"name": styles[i]})
							
							for(var i=0; i<count; i++)
								if(stylesModel.get(i).name == currentStyle)
									currentIndex = i
						}
					}
				}
			}
		}
	}
}
 

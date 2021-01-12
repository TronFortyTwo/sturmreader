/* Copyright 2020 Emanuele Sorce emanuele.sorce@hotmail.com
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */ 

// Style indipendent portable color palette
//	This also customize the theme we use for the app

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

QtObject {
	
	// See Main.qml - should be the same
 	Material.theme: Material.Dark
 	Material.primary: Material.Red
 	Material.accent: Material.DeepOrange
 	
	// TODO: better fallback colors
	
	// TODO: this is really bad actually
	
	property color background: "#FFFFFF"
	property color foreground: "#F7F7F7"
	property color item: "black"
	property color overlay: "white"
	property color shadow: "black"
	property color itemDetail: "black"
	property color negative: "#C7162B"
	property color positive: "#0E8420"
	
	Component.onCompleted: {
		// Set colors relevant to the current theme
		
		// Suru style
		if(styleSetting.currentStyle() == "Suru") {
			console.log("Color palette: Suru");
			
			background = Theme.palette.normal.background;
			item = Theme.palette.normal.baseText;
			overlay = Theme.palette.normal.overlay;
			shadow = Theme.palette.normal.base;
			itemDetail = Theme.palette.normal.base;
			negative = Theme.palette.normal.negative;
			positive = Theme.palette.normal.positive;
		}
		// Material style
		else if(styleSetting.currentStyle() == "Material") {
			console.log("Color palette: Material");
			
			background = Material.background;
			item = Material.foreground;
			overlay = Material.primary;
			shadow = Material.foreground;
			itemDetail = Material.accent;
			negative = Material.Red;
			positive = Material.Green;
		}
		else
			console.log("Color palette: Generic");
		
	}
}

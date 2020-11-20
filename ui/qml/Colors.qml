/* Copyright 2020 Emanuele Sorce emanuele.sorce@hotmail.com
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */ 

// Style indipendent portable color palette

import QtQuick 2.9

QtObject {
	
	// TODO: better fallback colors
	
	// TODO: this is really bad actually
	
	property color background: "#FFFFFF"
	property color foreground: "#F7F7F7"
	property color item: "black"
	property color text: "#111111"
	property color textFore: "black"
	property color textOver: "black"
	property color overlay: "white"
	property color shadow: "black"
	property color itemDetail: "black"
	property color negative: "#C7162B"
	property color positive: "#0E8420"
	
	Component.onCompleted: {
		
		// Try to guess what theme we are on and use its palette
		
		// Suru style
		if( typeof Theme !== 'undefined' &&
			typeof Theme.palette !== 'undefined' &&
			typeof Theme.palette.normal !== 'undefined') {
			
			console.log("Color palette: Suru");
			
			background = Theme.palette.normal.background;
			item = Theme.palette.normal.baseText;
			text = Theme.palette.normal.backgroundText;
			textFore = Theme.palette.normal.foregroundText;
			overlay = Theme.palette.normal.overlay;
			shadow = Theme.palette.normal.base;
			itemDetail = Theme.palette.normal.base;
			textOver = Theme.palette.normal.overlayText;
			negative = Theme.palette.normal.negative;
			positive = Theme.palette.normal.positive;
		}
		else
			console.log("Color palette: Portable");
		
	}
}

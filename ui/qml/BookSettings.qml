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

Item {
	id: bookStyles
	property bool loading: false
	property bool atdefault: false

	property string textColor
	property string fontFamily
	property real lineHeight
	property real fontScale
	property string background
	property real margin
	property real marginv
	property real bumper
	property string pdfBackground
	// real number coefficent that affects pdf quality scale (higher the better)
	property real pdfQuality
	
	property var defaults: ({
		textColor: "#222",
		fontFamily: "Default",
		lineHeight: 1,
		fontScale: 2,
		background: "url(.background_paper@30.png)",
		pdfBackground: "url(.background_paper@30.png)",
		margin: 0,
		marginv: 0,
		pdfQuality: 1
	})

	//onTextColorChanged: update()  // This is always updated with background
	onFontFamilyChanged: update()
	onLineHeightChanged: update()
	onFontScaleChanged: update()
	onBackgroundChanged: update()
	onPdfBackgroundChanged: update()
	onMarginChanged: update()
	onPdfQualityChanged: update()

	BookSettingsDialog {
		id: settingsDialog
	}
	function openDialog() {
		settingsDialog.open();
	}
	
	function load(styles) {
		loading = true
		textColor = styles.textColor || defaults.textColor
		fontFamily = styles.fontFamily || defaults.fontFamily
		lineHeight = styles.lineHeight || defaults.lineHeight
		fontScale = styles.fontScale || defaults.fontScale
		background = styles.background || defaults.background
		pdfBackground = styles.pdfBackground || defaults.pdfBackground
		margin = styles.margin || (pictureBook ? 0 : defaults.margin)
		marginv = styles.marginv || (pictureBook ? 0 : defaults.marginv)
		bumper = pictureBook ? 0 : 1
		pdfQuality = styles.pdfQuality || defaults.pdfQuality
		loading = false
	}

	function loadForBook() {
		var saved = getBookSetting("styles") || {}
		console.log(JSON.stringify(saved));
		load(saved)
	}

	function asObject() {
		return {
			textColor: textColor,
			fontFamily: fontFamily,
			lineHeight: lineHeight,
			fontScale: fontScale,
			background: background,
			pdfBackground: pdfBackground,
			margin: margin,
			marginv: marginv,
			bumper: bumper,
			pdfQuality: pdfQuality
		}
	}

	function update() {
		if (loading)
			return
		
		// book is not loaded
		if(bookWebView.url == "")
			return
		
		bookLoadingStart()
		
		// this one below should be improved
		bookWebView.runJavaScript("if(styleManager) styleManager.updateStyles(" + JSON.stringify(asObject()) + ");");
		if(!setBookSetting("styles", asObject()))
			console.log("Warning! Saving of book styles failed");
		atdefault = (JSON.stringify(asObject()) == JSON.stringify(defaults));
	}

	function resetToDefaults() {
		load({})
		update()
	}

	function saveAsDefault() {
		setSetting("defaultBookStyle", JSON.stringify(asObject()))
		defaults = asObject()
		atdefault = true
	}

	Component.onCompleted: {
		var targetwidth = 60
		var widthgu = width/scaling.dp(8)
		if (widthgu > targetwidth)
			// Set the margins to give us the target width, but no more than 30%.
			defaults.margin = Math.round(Math.min(50 * (1 - targetwidth/widthgu), 30))

		// load defaults
		var saveddefault = getSetting("defaultBookStyle")
		var savedvals = {}
		if (saveddefault)
			savedvals = JSON.parse(saveddefault)
		for (var prop in savedvals)
			if (prop in defaults)
				defaults[prop] = savedvals[prop]

		if (savedvals.marginv == undefined && widthgu > targetwidth)
			// Set the vertical margins to be the same as the horizontal, but no more than 5%.
			defaults.marginv = Math.min(defaults.margin, 5)
	}
}

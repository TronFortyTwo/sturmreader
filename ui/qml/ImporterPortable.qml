/* Copyright 2020 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3

Item {
	id: importer
	property Item importPage: null
	
	function pick(){
		picker.open();
	}
	
	FileDialog {
		id: picker
		
		title: gettext.tr("Choose the books to import")
		folder: shortcuts.home
		selectMultiple: true
		
		onAccepted: {
			var list = [];
			
			for(var i=0; i<picker.fileUrls.length; i++) {
				list.push({
					url: picker.fileUrls[i]
				});
			}
			
			importPage.importItems(list);
			
			picker.close();
		}
	}
}

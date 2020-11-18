 /*
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 * 
 * Copyright 2020 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */ 

import QtQuick 2.9
import QtQuick.Controls 2.2
 
Loader {
	
	Component.onCompleted: {
		// try load the UT importer.qml. if fails, use the portable one
		source = "Importer-ut.qml";
		if(status == Loader.error)
			source = "Importer-portable.qml";
	}
}

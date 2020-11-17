 /* Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.12
 
// This implements resolution indipendent scaling (using dp). If on Ubuntu Touch we use the system units.dp(), if not we use our own implementation

QtObject {
	
	// this is the best between dp_ut and dp_portable (defaults to portable one)
	property var dp: dp_portable
	
	// function that uses ut units.dp()
	function dp_ut(value) {
		return units.dp(value);
	}
	
	// function that uses our own implementation
	function dp_portable(value) {
		return portable_units.dp(value);
	}
	
	Component.onCompleted: {
		// if ut units.dp() exists, use that
		if(units && units.dp)
			dp = units.dp;
	}
}

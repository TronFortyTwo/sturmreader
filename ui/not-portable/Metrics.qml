/* Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import UserMetrics 0.1 as UUITK
import QtQuick 2.9

UUITK.Metric {
	id: pageMetric
	name: "page-turn-metric"
	format: gettext.tr("Pages read today: %1")
		emptyFormat: gettext.tr("No pages read today")
		domain: Qt.application.name
	
	function turnPage() {
		increment()
	}
}

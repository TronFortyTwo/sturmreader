/* Copyright 2020 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Item {
	id: importer
	property var activeTransfer: null
	property var pickerPage: picker
	property Item importPage: null
}

/* Copyright 2014 Robert Schroll
 * Copyright 2018 Emanuele Sorce
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3


Button {
    property bool primary: true
    color: primary ? UbuntuColors.green : UbuntuColors.silk
}

/*
 * Copyright (C) 2020 Emanuele Sorce emanuele.sorce@hotmail.com
 * Copyright (C) 2018 Rodney Dawes
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Sturm Reader is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "units.h"

#include <QGuiApplication>
#include <QScreen>

#include <cmath>

int Units::dp(double value) const
{
    auto screen = QGuiApplication::primaryScreen();

    // Ensure DPI is a valid value.
    auto dpi = screen->physicalDotsPerInch();
    if (std::isinf(dpi) || std::isnan(dpi) || dpi <= 0.0) {
        dpi = 160.0;
    }

    // Based on 160 DPI as 1:1 to match Android
    return qRound(value * (dpi / 160.0) * screen->devicePixelRatio());
}

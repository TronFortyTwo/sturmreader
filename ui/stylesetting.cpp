/*
 * Copyright (C) 2020 Emanuele Sorce emanuele.sorce@hotmail.com
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

#include "stylesetting.h"

#include <QQuickStyle>

StyleSetting::StyleSetting():
	field_name("qtquick2_style"),
	store("sturmreader.emanuelesorce", "sturmreader.emanuelesorce")
{
	auto styleList = availableStyles();
	
	QString default_style = "Suru";
	// If Suru style is not available, fallback to Material
	if(!styleList.contains("Suru"))
		default_style = "Material";
	
	// update from settings
	store.setValue(field_name, store.value(field_name, default_style));
	QString final_style = store.value(field_name).toString();
	
	// check that saved style is available, if not fallback to default
	if(!styleList.contains(final_style)) {
		final_style = default_style;
		store.setValue(field_name, final_style);
	}
	
	QQuickStyle::setStyle(final_style);
}

QStringList StyleSetting::availableStyles() {
	return QQuickStyle::availableStyles();
}

void StyleSetting::setStyle(const QString& style) {
	store.setValue(field_name, style);
}

QString StyleSetting::currentStyle() {
	return store.value(field_name).toString();
}

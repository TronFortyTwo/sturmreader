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

#ifndef STYLESETTING_H
#define STYLESETTING_H

#include <QObject>
#include <QtQml>
#include <QSettings>
#include <QString>

// This is just used to store the 
class StyleSetting : public QObject
{
Q_OBJECT

	QString field_name;
	QSettings store;

public:
	StyleSetting();
	
	Q_INVOKABLE
	QStringList availableStyles();
	
	Q_INVOKABLE
	void setStyle(const QString& style);
	
	Q_INVOKABLE
	QString currentStyle();
};

#endif

/*
 * Copyright 2020 Emanuele Sorce
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef GETTEXT_H
#define GETTEXT_H

#include <QObject>
#include <QString>

class Gettext : public QObject
{
	Q_OBJECT
	
	public:
	
		explicit Gettext(QObject *parent = 0);

		Q_INVOKABLE QString tr(const QString& text) const;
		Q_INVOKABLE QString tr(const QString& singular,
			const QString& plural,
			int n) const;
};

#endif

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

#ifndef UNITS_H
#define UNITS_H

#include <QObject>

class Units : public QObject
{
	Q_OBJECT

	public:
		
		Q_INVOKABLE int dp(double value) const;
};

#endif // FONTLISTER_H

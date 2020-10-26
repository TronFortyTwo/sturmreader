/*
 * Copyright 2018 Rodney Dawes
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

#include "gettexttr.h"

#include <QDebug>
#include <QDir>

#include <cstdlib>
#include <string>
#include <locale>
#include <libintl.h>

#include <QCoreApplication>
#include <QRegularExpression>
#include <QString>
#include <QtGlobal>

/*! Get the translated version of a string
 *
 * @param text The untranslated version of a string to be translated
 * @return The translated version of text
 */
QString Gettext::tr(const QString& text) const
{
	return QString::fromUtf8(gettext(text.toUtf8()));
}

/*! Get the translated version of a possibly pluralized string
 *
 * @param singular The untranslated version of the string to be translated,
 *     in singular form
 * @param plural The untranslated version of the string to be translated,
 *     in plural form
 * @param n The value for determining the correct singular or plural form of
 *     the translated version of the string
 * @return The translated version of singular or plural
 */
QString Gettext::tr(const QString& singular,
	const QString& plural,
	int n) const
{
	return QString::fromUtf8(ngettext(singular.toUtf8(), plural.toUtf8(), n));
}

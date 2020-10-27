/*
 * Copyright (C) 2020 emanuele.sorce@hotmail.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * test is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "gettext.h"

#include <QCoreApplication>
#include <QRegularExpression>
#include <QString>
#include <QtGlobal>
#include <QDebug>

#include <locale>
#include <libintl.h>
#include <string>

std::string domainDir()
{
	// First try for click packages on Ubuntu Touch
	auto appDir = qgetenv("APP_DIR").toStdString();
	if (!appDir.empty()) {
		return appDir;
	}

	// Next check if we're a snap package on Linux
	appDir = qgetenv("SNAP").toStdString();
	if (!appDir.empty()) {
		return appDir;
	}

	// Next use Qt's applicationDirPath, and strip `bin` from the end
	auto path = QCoreApplication::applicationDirPath();
	if (path.endsWith("/bin")) {
		return path.remove(QRegularExpression("/bin$")).toStdString();
	} else {
		return path.toStdString();
	}

	// If everything else fails, fall back to `/usr` as prefix
	return std::string{"/usr"};
}

Gettext::Gettext(QObject* parent):
	QObject(parent)
{
	setDomain("sturmreader.emanuelesorce");
}

QString Gettext::tr(const QString& text) const {
		return QString::fromUtf8(gettext(text.toUtf8()));
}

QString Gettext::tr(const QString& singular, const QString& plural, int n) const {
	return QString::fromUtf8(ngettext(singular.toUtf8(), plural.toUtf8(), n));
}

void Gettext::setDomain(const QString& domain) {
	textdomain(domain.toUtf8());

	// Find the path
	auto app_dir = domainDir();
	QString locale_path;

	if (!app_dir.empty() && QDir::isAbsolutePath(app_dir.c_str()))
		locale_path = QDir(app_dir.c_str()).filePath(QStringLiteral("share/locale"));
	else
		locale_path = QStringLiteral("/usr/share/locale");
	
	qDebug() << locale_path;
	
	bindtextdomain(domain.toUtf8(), locale_path.toUtf8());
}

#include "gettext.moc"

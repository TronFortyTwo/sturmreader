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
 
#include <QObject>
#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QDebug>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtQml>
#include <QObject>

class Gettext : public QObject
{
Q_OBJECT

public:

	explicit Gettext(QObject* parent = 0);
	//virtual ~Gettext(){}
	
	Q_INVOKABLE
	QString tr(const QString& text) const;
	
	Q_INVOKABLE
	QString tr(const QString& singular, const QString& plural, int n) const;
	
	void setDomain(const QString& domain);
	
	//Q_DISABLE_COPY(Gettext)
};

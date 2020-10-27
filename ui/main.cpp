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

#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QDebug>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QObject>
#include <QQmlEngine>
#include <QQmlContext>

#include <string>
#include <locale>
#include <libintl.h>

#include "gettext.h"

// =================
// Launcher function
// =================
int main(int argc, char *argv[])
{
	//QApplication::setAttribute(Qt::AA_DisableHighDpiScaling);
	QQuickStyle::setStyle("Suru");

	QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
	app->setApplicationName("sturmreader.emanuelesorce");

	Gettext gt;
	
	qDebug() << "Starting";

	QQmlApplicationEngine engine;
	engine.rootContext()->setContextProperty("gettext", &gt);
	engine.load("ui/main.qml");
	
	return app->exec();
}
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
#include <QLoggingCategory>

#include <string>
#include <locale>
#include <libintl.h>

#include "gettext.h"
#include "units.h"
#include "fontlister.h"
#include "filesystem.h"
#include "qhttpserver/qhttpserver.h"
#include "qhttpserver/fileserver.h"
#include "qhttpserver/qhttprequest.h"
#include "qhttpserver/qhttpresponse.h"
#include "reader/epubreader.h"
#include "reader/cbzreader.h"
#include "reader/pdfreader.h"

// =================
// Launcher function
// =================
int main(int argc, char *argv[])
{
	QLoggingCategory::setFilterRules("qt.qml.connections=false");
	
	QString app_name = "sturmreader.emanuelesorce";
	
	QQuickStyle::setStyle("Suru");
	QQuickStyle::setFallbackStyle("Material");

	QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
	app->setApplicationName(app_name);
	//app->setOrganizationName(QString("emanuelesorce"));
	//app->setOrganizationDomain(QString("emanuelesorce.com"));
	
	Gettext gt;
	Units un;
	FontLister fl;
	FileSystem fs;
	QHttpServer http_server;
	FileServer file_server;
	EpubReader epub;
	PDFReader pdf;
	CBZReader cbz;
	
	qDebug() << "Starting";

	QQmlApplicationEngine engine;
	
	engine.rootContext()->setContextProperty("gettext", &gt);
	engine.rootContext()->setContextProperty("portable_units", &un);
	engine.rootContext()->setContextProperty("qtfontlist", &fl);
	engine.rootContext()->setContextProperty("filesystem", &fs);
	engine.rootContext()->setContextProperty("fileserver", &file_server);
	engine.rootContext()->setContextProperty("httpserver", &http_server);
	qmlRegisterUncreatableType<QHttpRequest>("HttpUtils", 1, 0, "HttpRequest", "Do not create HttpRequest directly");
	qmlRegisterUncreatableType<QHttpResponse>("HttpUtils", 1, 0, "HttpResponse", "Do not create HttpResponse directly");
	engine.rootContext()->setContextProperty("epubreader", &epub);
	engine.rootContext()->setContextProperty("pdfreader", &pdf);
	engine.rootContext()->setContextProperty("cbzreader", &cbz);
	
	// Test if we are on ubuntu touch
	bool ubuntu_touch = false;
	
	QStringList import_path_list = engine.importPathList();
	for (int i = 0; i < import_path_list.size(); ++i) {
		QString import_path = import_path_list.at(i);
		
		if( import_path.contains("/opt/click.ubuntu.com/" + app_name) ) {
			ubuntu_touch = true;
			break;
		}
	}
	
	qDebug() << "Ubuntu Touch imports found: " << (ubuntu_touch ? "Yes" : "No");
	
	if(ubuntu_touch) {
		qmlRegisterType(QUrl("file:./ui/qml/ImporterUT.qml"), "Importer", 1, 0, "Importer");
		qmlRegisterType(QUrl("file:./ui/qml/MetricsUT.qml"), "Metrics", 1, 0, "Metrics");
	} else { // portable
		qmlRegisterType(QUrl("file:./ui/qml/ImporterPortable.qml"), "Importer", 1, 0, "Importer");
		qmlRegisterType(QUrl("file:./ui/qml/MetricsPortable.qml"), "Metrics", 1, 0, "Metrics");
	}

	engine.load("ui/qml/Main.qml");
	
	return app->exec();
}

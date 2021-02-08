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
#include <QIcon>

#include <string>
#include <locale>
#include <libintl.h>

#include "gettext.h"
#include "units.h"
#include "stylesetting.h"
#include "fontlister.h"
#include "filesystem.h"
#include "qhttpserver/qhttpserver.h"
#include "qhttpserver/fileserver.h"
#include "qhttpserver/qhttprequest.h"
#include "qhttpserver/qhttpresponse.h"
#include "reader/epubreader.h"
#include "reader/pdfreader.h"

// =================
// Launcher function
// =================
int main(int argc, char *argv[])
{
	// This is to prevent deprecated connections sintax on 5.15,
	// not yet supported on 5.9 or 5.12. When the minimum will be 5.15 we can remove this line
	QLoggingCategory::setFilterRules("qt.qml.connections=false");
	
	// Application
	QString app_name = "sturmreader.emanuelesorce";
	QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
	app->setApplicationName(app_name);
	app->setWindowIcon(QIcon(":sturmreader.svg"));
	
	// styling
	StyleSetting styleSetting;
	// localization
	Gettext gt;
	// device indipendent pixels
	Units un;
	// Qt available fonts
	FontLister fl;
	// file operations
	FileSystem fs;
	// http server
	QHttpServer http_server;
	FileServer file_server;
	// book parsers
	EpubReader epub;
	PDFReader pdf;

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
	engine.rootContext()->setContextProperty("styleSetting", &styleSetting);
	
	
	// Test what platform we are in
	const int PLATFORM_UT		= 0;	// Ubuntu Touch
	const int PLATFORM_ANDROID	= 1;	// Android
	// What is required to port Sturm Reader to Android
	// 1) Using QRC (done)
	// 2) Not depending on WebEngineView (partial)
	//		- Find a way to communicate with WebView
	// 3) Platform detection
	// 4) Importing of files
	// 5) CMake build configuration
	// 6) Everything else that comes up
	const int PLATFORM_GENERIC	= 2;	// None of the previous
	int platform = PLATFORM_GENERIC;
	
	// check we are in ubuntu touch
	QString ubuntu_touch_prefix = "/opt/click.ubuntu.com/";
	
	QStringList import_path_list = engine.importPathList();
	for (int i = 0; i < import_path_list.size(); ++i) {
		QString import_path = import_path_list.at(i);
		
		if( import_path.contains(ubuntu_touch_prefix + app_name) ) {
			platform = PLATFORM_UT;
			break;
		}
	}
	
	// check we are in Android
	// platform = PLATFORM_ANDROID
	
	qDebug() << "Platform detected: " << (PLATFORM_UT ? "Ubuntu Touch" :
		PLATFORM_ANDROID ? "Android" : "Generic" );
	
	// Load right stuff
	if(platform == PLATFORM_UT) {
		qmlRegisterType(QUrl("qrc:///qml/ImporterUT.qml"), "Importer", 1, 0, "Importer");
		qmlRegisterType(QUrl("qrc:///qml/MetricsUT.qml"), "Metrics", 1, 0, "Metrics");
		qmlRegisterType(QUrl("qrc:///qml/WebViewPortable.qml"), "Browser", 1, 0, "Browser");
	} else if(platform == PLATFORM_ANDROID){
		qmlRegisterType(QUrl("qrc:///qml/ImporterPortable.qml"), "Importer", 1, 0, "Importer");
		qmlRegisterType(QUrl("qrc:///qml/MetricsPortable.qml"), "Metrics", 1, 0, "Metrics");
		qmlRegisterType(QUrl("qrc:///qml/WebViewAndroid.qml"), "Browser", 1, 0, "Browser");
	} else if(platform == PLATFORM_GENERIC){
		qmlRegisterType(QUrl("qrc:///qml/ImporterPortable.qml"), "Importer", 1, 0, "Importer");
		qmlRegisterType(QUrl("qrc:///qml/MetricsPortable.qml"), "Metrics", 1, 0, "Metrics");
		qmlRegisterType(QUrl("qrc:///qml/WebViewPortable.qml"), "Browser", 1, 0, "Browser");
	}
	
	engine.load("qrc:///qml/Main.qml");
	
	return app->exec();
}

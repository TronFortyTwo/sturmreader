/* Copyright 2013-2015 Robert Schroll
 * Copyright 2019 Emanuele Sorce
 *
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

#include "filesystem.h"
#include <QFileInfo>
#include <QDir>
#include <QDirIterator>
#include <QStandardPaths>
#include <QTemporaryFile>
#include <QDebug>
#include <stdlib.h>

bool FileSystem::execb(const QString& cmd)
{
        unsigned int r = exec(cmd);

        if(r==0)
		return false;
        return true;
}

unsigned int FileSystem::exec(const QString& cmd)
{
        qDebug() << "bash exec: " << cmd;

        int result;
	unsigned int exit_code;

	/* QProcess implementation
	 *
	result = QProcess::execute(cmd);
        exit_code = static_cast<unsigned int>(result);

	if(result == -2)
		qDebug() << "-> process cannot be started";
	else if(result == -1)
		qDebug() << "-> process crashed";
	else
	{
      		qDebug() << "-> exit code: " << exit_code;
		qDebug() << "-> exit code: (u)" << static_cast<unsigned int>(exit_code);
	}
	*/

	// Stdlib implementation
	QByteArray ba = cmd.toLocal8Bit();
	const char *c_cmd = ba.data();

	result = system(c_cmd);
	exit_code = static_cast<unsigned int>(result);

	qDebug() << "-> exit code: " << exit_code;
	//qDebug() << "-> exit code (u): " << exit_code;

        return exit_code;
}

/*
 * Return 0 if file does not exist, 2 if file is directory, 1 otherwise.
 */
int FileSystem::exists(const QString &filename)
{
    QFileInfo fileinfo(filename);
    if (!fileinfo.exists())
        return 0;
    return fileinfo.isDir() ? 2 : 1;
}

QString FileSystem::canonicalFilePath(const QString &filename)
{
    QFileInfo fileinfo(filename);
    return fileinfo.canonicalFilePath();
}

bool FileSystem::makeDir(const QString &path)
{
    QDir dir("");
    return dir.mkpath(path);
}

QString FileSystem::homePath() const
{
    return QDir::homePath();
}

bool FileSystem::readableHome()
{
    // .bash_logout in not readable under confinement
    QFile canary(QDir::homePath() + "/.bash_logout");
    if (canary.open(QFile::ReadOnly)) {
        canary.close();
        return true;
    }
    return false;
}

/*
 * Get a subdirectory of XDG_DATA_HOME.  Return the path of the directory, or the empty string
 * if something went wrong.
 */
QString FileSystem::getDataDir(const QString &subDir)
{
    QString XDG_data = QStandardPaths::writableLocation(QStandardPaths::DataLocation) + "/" + subDir;
    QDir dir("");
    if (!dir.mkpath(XDG_data))
        return QString();

    QFileInfo info(XDG_data);
    if (!info.isWritable())
        return QString();

    return XDG_data;
}

/*
 * Return the absolute path of all files within dirname or its subdirectories that match filters.
 */
QStringList FileSystem::listDir(const QString &dirname, const QStringList &filters)
{
    QStringList files;
    QDirIterator iter(dirname, filters, QDir::Files | QDir::Readable, QDirIterator::Subdirectories);
    while (iter.hasNext())
        files.append(iter.next());
    return files;
}

/*
 * Guess at the type of a file from its magic number.
 */
QString FileSystem::fileType(const QString &filename) {
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
        return "unreadable";

    QByteArray bytes = file.read(60);
    if (bytes.left(4) == "%PDF") {
        return "PDF";
    } else if (bytes.left(2) == "PK") {
        if (bytes.mid(30, 28) == "mimetypeapplication/epub+zip")
            return "EPUB";
        return "CBZ";
    }
    return "unknown";
}

bool FileSystem::remove(const QString &filename) {
    return QFile::remove(filename);
}

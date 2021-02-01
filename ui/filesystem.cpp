/* Copyright 2013-2015 Robert Schroll
 *
 * Copyright 2020 Emanuele Sorce
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
 * see https://en.wikipedia.org/wiki/List_of_file_signatures
 */
QString FileSystem::fileType(const QString &filename) {
	
	int file_status = exists(filename);
	
	if(file_status == 2) return "directory";
	else if(file_status == 0) return "not existent";
	
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
        return "unreadable";

	QByteArray bytes = file.read(64);
	if (bytes.left(4) == "%PDF") {
		return "PDF";
	} else if (bytes.left(2) == "PK") {
		if (bytes.mid(30, 28) == "mimetypeapplication/epub+zip")
			return "EPUB";
		
		// not sure - use file name extension before fallbacking to CBZ
		QFileInfo fileInfo(filename);
		
		if(fileInfo.suffix().toLower() == "epub")
			return "EPUB";
		
		return "CBZ";
    }
    return "unknown";
}

bool FileSystem::remove(const QString &filename) {
    return QFile::remove(filename);
}

bool FileSystem::copy(const QString& source, const QString& dest) {
	QFile source_file(source);
	
	if (!source_file.copy(dest)) {
		qDebug() << "Copy error: " << source_file.error();
		qDebug() << "Source: " << source;
		qDebug() << "Dest: " << dest;
		return false;
	}
	return true;
}

#include <quazip.h>
#include <quazipfile.h>
#include <QProcess>
#include <QFile>
#include <QFileDevice>
#include <JlCompress.h>

bool FileSystem::convertCbz2Pdf(const QString& cbzfile, const QString& pdffile) {
	
	// Destination must be clear - temp directory must not exist - source must exist
	if(exists(pdffile)) {
		qDebug() << "Pdf file already exists";
		return false;
	}
	if(!exists(cbzfile)){
		qDebug() << "CBZ file already exists";
		return false;
	}
	
	
	// extract to temp directory
	QString temp_dir = cbzfile + "_TEMP";
	if(!makeDir(temp_dir)) {
		qDebug() << "Can't create temp directory" << temp_dir;
		return false;
	}
	
	QStringList files = JlCompress::extractDir(cbzfile, temp_dir);
	if(files.length() == 0) {
		qDebug() << "extraction failed";
		return false;
	}
	
	// build pdf using podofoimg2pdf
	QStringList conv_args;
	conv_args << pdffile;
	conv_args << files;
	
	int result = QProcess::execute("podofoimg2pdf", conv_args);
	
	if(result == -2)
		qDebug() << "podofoimg2pdf process cannot be started";
	else if(result == -1)
		qDebug() << "podofoimg2pdf process crashed";
	else if(result > 0)
		qDebug() << "podofoimg2pdf process returned error: " << result;
	
	// clean up directory
	if(!QDir(temp_dir).removeRecursively())
		qDebug() << "cannot remove temp files";
	
	// if successfull, remove CBZ file
	if(result == 0 && !QFile(cbzfile).remove())
		qDebug() << "cannot remove old CBZ file";
	
	return result == 0;
}

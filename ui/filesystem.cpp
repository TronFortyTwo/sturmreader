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
	if(!file.open(QIODevice::ReadOnly))
		return "unreadable";

	QByteArray bytes = file.read(64);
	// PDF
	if (bytes.left(4) == "%PDF") {
		return "PDF";
	// ZIP FILE (epub, cbz)
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
#include <QUrl>
#include <QFileDevice>
#include <JlCompress.h>
#include <string>

bool FileSystem::convertCbz2Pdf(const QString& cbzfile, const QString& pdffile) {
	
	if(!exists(cbzfile)){
		qDebug() << "CBZ file doesn't exists";
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
	
	if(exists(pdffile)) {
		qDebug() << "Pdf file already exists";
		return false;
	}
	
	QStringList destpathlist = pdffile.split("/");
	QString output_filename = destpathlist.takeLast();
	QString destpath = destpathlist.join("/");
	
	int result = convertComicDir2Pdf(temp_dir, destpath, output_filename);
	
	// if successfull, remove CBZ file
	if(result && !QFile(cbzfile).remove())
		qDebug() << "cannot remove old CBZ file";
	
	return result;
}

bool FileSystem::convertComicDir2Pdf(const QString& comicdir, const QString& destpath, const QString& pdffile) {
	QStringList files = QDir(comicdir).entryList(QDir::Files, QDir::Name);
	QStringList dirs = QDir(comicdir).entryList(QDir::Dirs, QDir::Name);
	
	// if some conversion occurred
	bool converted_something = false;
	
	// subfolders are other comics
	for(int i=0; i<dirs.length(); i++) {
		if(dirs[i] == "." || dirs[i] == "..") continue;
		if(!convertComicDir2Pdf(comicdir + "/" + dirs[i], destpath, comicdir.split("/").takeLast() + " | " + dirs[i] + ".pdf")) {
			qDebug() << "comic book subdirectory can't be turned in a book";
			if(!QDir(comicdir).removeRecursively())
				qDebug() << "cannot remove comic book directory";
			return false;
		}
		else converted_something = true;
	}
	
	// pick only the files of supported format
	QStringList pages;
	for(int i=0; i<files.length(); i++) {
		// this will store if it's a valid page
		bool accepted = false;
		
		QStringList supported_extensions = {
			// https://www.mankier.com/1/podofoimg2pdf
			".jpg", ".jpeg", ".jpe", ".jif", ".jfif", ".jfi",	// JPEG
			".png",												// PNG
			".tiff", ".tif"										// TIFF
		};
		// config files and metadata - ignored but don't fail
		// See https://wiki.mobileread.com/wiki/CBR_and_CBZ
		QStringList ignored_extensions = {
			".xml", ".config", ".json", ".acbf"
		};
		
		// is a supported extension?
		for(int e=0; e<supported_extensions.length(); e++){
			if(files[i].endsWith(supported_extensions[e], Qt::CaseInsensitive)){
				accepted = true;
				break;
			}
		}
		
		if(accepted)
			pages << comicdir + "/" + files[i];
		else {
			// is an ignored extension?
			bool ignore = false;
			for(int e=0; e<ignored_extensions.length(); e++){
				if(files[i].endsWith(ignored_extensions[e], Qt::CaseInsensitive)){
					ignore = true;
					break;
				}
			}
			// it is a fail!
			if(!ignore) {
				qDebug() << "unsupported image file: " << files[i];
				if(!QDir(comicdir).removeRecursively())
					qDebug() << "cannot remove comic book directory";
				return false;
			}
		}
	}
	
	if(!pages.empty()) {
		// build pdf using podofoimg2pdf
		QStringList conv_args;
		conv_args << destpath + "/" + pdffile;
		conv_args << pages;
	
		int result = QProcess::execute("podofoimg2pdf", conv_args);
	
		if(result == -2)
			qDebug() << "podofoimg2pdf process cannot be started";
		else if(result == -1)
			qDebug() << "podofoimg2pdf process crashed";
		else if(result > 0)
			qDebug() << "podofoimg2pdf process returned error: " << result;
	
		// clean up directory
		if(!QDir(comicdir).removeRecursively())
			qDebug() << "cannot remove comic book directory";
	
		return result == 0;
	}
	else {
		if(!QDir(comicdir).removeRecursively())
			qDebug() << "cannot remove comic book directory";
		if(converted_something)
			return true;
		else
			return false;
	}
}

/* Copyright 2013, 2015 Robert Schroll
 *
 * Copyright 2020 Emanuele Sorce
 * 
 * This file is part of Beru and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

#ifndef FILESYSTEM_H
#define FILESYSTEM_H

#include <QObject>
#include <QStringList>

class FileSystem : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE int exists(const QString &filename);
    Q_INVOKABLE QString canonicalFilePath(const QString &filename);
    Q_INVOKABLE bool makeDir(const QString &path);
    Q_INVOKABLE QString homePath() const;
    Q_INVOKABLE bool readableHome();
    Q_INVOKABLE QString getDataDir(const QString &subDir);
    Q_INVOKABLE QStringList listDir(const QString &dirname, const QStringList &filters);
    Q_INVOKABLE QString fileType(const QString &filename);
    Q_INVOKABLE bool remove(const QString &filename);
	Q_INVOKABLE bool copy(const QString& source, const QString& dest);
	
	// TODO: maybe move next ones to better place? Is not very filesystemy
	// convert the cbz file named cbzfile to a pdf file named pdffile
	Q_INVOKABLE
	bool convertCbz2Pdf(const QString& cbzfile, const QString& pdffile);
	// convert an extracted comic book to a pdf file
	Q_INVOKABLE
	bool convertComicDir2Pdf(const QString& comicdir, const QString& destpath, const QString& pdffile);
};

#endif // FILESYSTEM_H

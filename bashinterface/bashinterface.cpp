/* Copyright 2019 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

#include "bashinterface.h"

#include <QString>
#include <QDebug>

bool Bashinterface::execb(const QString& cmd) const
{
	int r = exec(cmd);

	if(r==0) return false;
	return true;
}

int Bashinterface::exec(const QString& cmd) const
{
	qDebug() << "bash exec: " << cmd;

	int result;

	QStringList args = cmd.split(" ");

	if(args.count() > 0)
	{
		QString program = args.takeFirst();
		result = QProcess::execute(program, args);
	}
	qDebug() << "-> exit code: " << result;

	return result;
}

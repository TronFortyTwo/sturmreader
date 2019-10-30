/* Copyright 2019 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPLv3. See the file COPYING for full details.
 */

#ifndef BASHINTERFACE_H
#define BASHINTERFACE_H

#include <QObject>
#include <QString>
#include <QProcess>

class Bashinterface : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE int exec(const QString& cmd) const;
    Q_INVOKABLE bool execb(const QString& cmd) const;
};

#endif

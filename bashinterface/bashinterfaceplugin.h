/* Copyright 2019 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

#ifndef FONTLISTERPLUGIN_H
#define FONTLISTERPLUGIN_H

#include <QQmlExtensionPlugin>

class BashinterfacePlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "io.github.rschroll.Bashinterface")

public:
    void registerTypes(const char *uri);
};

#endif // FONTLISTERPLUGIN_H

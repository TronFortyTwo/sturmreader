/* Copyright 2019 Emanuele Sorce
 *
 * This file is part of Sturm Reader and is distributed under the terms of
 * the GPL. See the file COPYING for full details.
 */

#include "bashinterfaceplugin.h"
#include "bashinterface.h"
#include <qqml.h>

void BashinterfacePlugin::registerTypes(const char *uri)
{
    qmlRegisterType<Bashinterface>(uri, 1, 0, "Bashinterface");
}

#ifndef MIMETYPE_H
#define MIMETYPE_H

#include <QString>
#include <QStringList>
#include <QHash>

// http://stackoverflow.com/questions/6576036/initialise-global-key-value-hash
typedef QHash<QString, QString> StringHash;

StringHash initMimeTypes();

QString guessMimeType(const QString &filename);

#endif // MIMETYPE_H

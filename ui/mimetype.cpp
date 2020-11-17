#include "mimetype.h"

const StringHash MIMETYPES = initMimeTypes();

StringHash initMimeTypes()
{
    StringHash hash;
    hash["html"] = "text/html";
    hash["htm"] = "text/html";
    hash["xhtml"] = "application/xhtml+xml";
    hash["xml"] = "application/xml";
    hash["png"] = "image/png";
    hash["gif"] = "image/png";
    hash["jpeg"] = "image/jpeg";
    hash["svg"] = "image/svg+xml";
    hash["js"] = "application/javascript";
    hash["css"] = "text/css";
    hash["opf"] = "application/oebps-package+xml";
    hash["ncx"] = "application/x-dtbncx+xml";
    return hash;
}

QString guessMimeType(const QString &filename) {
    return MIMETYPES.value(filename.split('.').last(), "application/octet-stream");
}

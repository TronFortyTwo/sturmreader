Ebook Reader for Ubuntu
=======================
Sturm reader is an ebook reader for Ubuntu.  It's built on the the new Ubuntu
Toolkit, so it works best on touch devices.  It behaves resonably on the
desktop, as well. It features full support for Epub files and
preliminary support for CBZ and PDF files.

It's a fork of Beru from Rschroll (http://rschroll.github.io/beru), thanks!

Building
--------
To build for the system you are working on, do
```
$ mkdir <build directory>
$ cd <build directory>
$ cmake <path to source>
$ make
```

To build the click for an Ubuntu Touch device and create a .click package, you can just use clickable
```
$ clickable
# Or to build the plus version:
$ CLICKABLE_BUILD_ARGS="-DPLUS_VERSION=on" clickable
```
To enable DRM support in the calibre backend, install the included dedrm plugin in the container calibre installation

Running
-------
Launch Sturm Reader with the shell script `sturmreader`.

Sturm Reader keeps a library of epub files.  On every start, a specified folder
is searched and all epubs in it are included in the library.  You may
also pass a epub file as an argument.  This will open the file
and add it to your library.

The Library is stored in a local database.  While I won't be
cavalier about changing the database format, it may happen.  If
you're getting database errors after upgrading, delete the database
and reload your files.  The database is one of the ones in
`~/.local/share/sturmreader.emanuelesorce/Databases`;
read the `.ini` files to find the one with `Name=BeruLocalBooks`.


Known Problems
--------------
Known bugs are listed on the [issue tracker][3].  If you don't see
your problem listed there, please add it!

[1]: http://developer.ubuntu.com/start/ubuntu-sdk/installing-the-sdk/ "Ubuntu SDK"
[2]: http://developer.ubuntu.com/apps/sdk/tutorials/building-cross-architecture-click-applications/ "Click tutorial"
[3]: https://github.com/tronfortytwo/beru/issues "Bug tracker"

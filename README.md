Ebook Reader for Ubuntu
=======================
Sturm reader is an ebook reader for Ubuntu.  It's built on the the new Ubuntu
Toolkit, so it works best on touch devices.  It behaves resonably on the
desktop, as well. It features full support for Epub files and
preliminary support for CBZ and PDF files.

It's a fork of Beru from Rschroll (http://rschroll.github.io/beru), thanks!

Building
--------
To build for the systen you are working on, do
```
$ mkdir <build directory>
$ cd <build directory>
$ cmake <path to source>
$ make
```

To build the click for an Ubuntu Touch device and create a .click package, you can use clickable:
```
$ clickable b p
```
Or inside an OnTheRoad container
```
$ clickable b p --container-mode
```

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

Click Packages
--------------
The install option target can be used to help build click packages.
First, run cmake with the `-DCLICK_MODE=ON` option.  Then run from the
build directory
```
make DESTDIR=<directory> install
```
This will fill the directory with the contents for the click package,
which may be assembed with
```
click build <directory>
```
To build clicks from within Qt Creator, add `-DCLICK_MODE=ON` to the
CMake arguments of the build settings.

Note that the click package contains .so files, and is therefore
limited to the architecture on which it was produced.  To produce
click packages for other architectures, you'll need to [cross
compile][2].

Known Problems
--------------
Known bugs are listed on the [issue tracker][3].  If you don't see
your problem listed there, please add it!

[1]: http://developer.ubuntu.com/start/ubuntu-sdk/installing-the-sdk/ "Ubuntu SDK"
[2]: http://developer.ubuntu.com/apps/sdk/tutorials/building-cross-architecture-click-applications/ "Click tutorial"
[3]: https://github.com/tronfortytwo/beru/issues "Bug tracker"

[![Donate](https://img.shields.io/badge/PayPal-Donate%20to%20Author-blue.svg)](https://www.paypal.me/emanuele42)
[![OpenStore](https://img.shields.io/badge/Install%20from-OpenStore-000000.svg)](https://open-store.io/app/sturmreader.emanuelesorce)

Ebook Reader for Mobile Devices
===============================
Sturm reader is an ebook reader for Linux focused on touch and portable devices.  It's built now for Ubuntu Touch and Alpine Linux (so postmarketOS).
It has features to style the book.
It features full support for Epub, PDF and CBZ files.

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
```

Known Problems
--------------
Known bugs are listed on the [issue tracker][1].  If you don't see
your problem listed there, please add it!

[1]: https://github.com/tronfortytwo/sturmreader/issues "Bug tracker"

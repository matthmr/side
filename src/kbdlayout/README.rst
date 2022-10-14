kbdlayout
=========

Prints the keyboard layout to ``STDOUT``.

Building
--------

Run ``make kbdlayout`` to build the program. ``make`` variables are:

* ``CC`` : the C compiler (gcc)
* ``CFLAGS`` : flags to pass to the compiler (-Wall)
* ``CFLAGSADD``: additional flags to pass to the compiler ()

Usage
-----

Simply run ``kbdlayout``. It takes no arguments and outputs results as
seen in the ``XkbLayout`` and ``XkbVariant`` sections for keyboards
under X.

This is very useful for users of window managers that don't support
systrays. Otherwise just use a `layout manager`_.

.. _layout manager: https://wiki.archlinux.org/title/Xorg/Keyboard_configuration

Test web application
====================
This is a very simple test web application that can run in foreground mode and
daemon mode. Its only purpose is to return a very simple static HTML page.

The most interesting part of this example is probably the daemonize
infrastructure (`daemonize.h`, `daemonize.c`) -- I have been trying to closely
follow systemd's recommendations for implementing traditional SysV daemons
(more info:`man 7 daemon`) sticking myself to POSIX standards as much as
possible.

To keep the code as clear as possible, I have encapsulated each recommended
step into a function abstraction, and every failure yields a distinct error
code so that we can easily trace the origins of the error.

The daemonize infrastructure is very generic -- you only need to provide a
pointer to a function that initializes the daemon's state and a pointer to
a function that runs the main loop.

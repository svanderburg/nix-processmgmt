#ifndef __SERVICE_H
#define __SERVICE_H
#include "daemonize.h"

int run_foreground_process(int port);

DaemonStatus run_daemon(int port, const char *pid_file);

#endif

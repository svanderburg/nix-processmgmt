#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "service.h"

#define TRUE 1
#define FALSE 0

int main(int argc, char *argv[])
{
    unsigned int i;
    int run_as_daemon = FALSE;
    int port;
    char *port_value = getenv("PORT");

    if(port_value == NULL)
    {
        fprintf(stderr, "We need a PORT environment variable that specifies to which port the HTTP service should bind to!\n");
        return 1;
    }

    port = atoi(port_value);

    for(i = 1; i < argc; i++)
    {
        if(strcmp(argv[i], "-D") == 0)
            run_as_daemon = TRUE;
    }

    if(run_as_daemon)
    {
        char *pid_file = getenv("PID_FILE");

        if(pid_file == NULL)
        {
            fprintf(stderr, "We need the PID_FILE environment variable that specifies the path to a file storing the PID of the daemon process!\n");
            return 1;
        }

        return run_daemon(port, pid_file);
    }
    else
        return run_foreground_process(port);
}

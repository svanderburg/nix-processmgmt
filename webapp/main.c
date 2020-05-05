/*
 * Copyright 2020 Sander van der Burg
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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

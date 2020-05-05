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

#include "service.h"
#include <microhttpd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <signal.h>

#define TRUE 1
#define FALSE 0

#define PAGE_TEMPLATE "<!DOCTYPE html>\n"\
    "<html>\n"\
    "  <head>\n"\
    "    <title>Simple test webapp</title>\n"\
    "  </head>\n"\
    "  <body>\n"\
    "    Simple test webapp listening on port: %d\n"\
    "  </body>\n"\
    "</html>\n"

static int ahc_echo(void *cls, struct MHD_Connection *connection, const char *url, const char *method, const char *version, const char *upload_data, size_t *upload_data_size, void **ptr)
{
    static int dummy;
    const char *page = cls;
    struct MHD_Response *response;
    int ret;

    if(strcmp(method, "GET") != 0)
        return MHD_NO; /* unexpected method */

    if(&dummy != *ptr)
    {
        /* The first time only the headers are valid,
           do not respond in the first round... */
        *ptr = &dummy;
        return MHD_YES;
    }

    if (*upload_data_size != 0)
        return MHD_NO; /* upload data in a GET!? */

    *ptr = NULL; /* clear context pointer */

    response = MHD_create_response_from_buffer(strlen(page), (void*)page, MHD_RESPMEM_PERSISTENT);
    ret = MHD_queue_response(connection, MHD_HTTP_OK, response);

    MHD_destroy_response(response);
    return ret;
}

volatile int terminated = FALSE;

static void handle_shutdown(int signum)
{
    terminated = TRUE;
}

typedef struct
{
    char *page;
    struct MHD_Daemon *daemon;
}
DaemonWrapper;

static DaemonWrapper *create_daemon_wrapper(int port)
{
    DaemonWrapper *wrapper = (DaemonWrapper*)malloc(sizeof(DaemonWrapper));
    wrapper->page = (char*)malloc(sizeof(PAGE_TEMPLATE) + 10);

    sprintf(wrapper->page, PAGE_TEMPLATE, port);

    wrapper->daemon = MHD_start_daemon(MHD_USE_THREAD_PER_CONNECTION, port, NULL, NULL, &ahc_echo, wrapper->page, MHD_OPTION_END);

    if(wrapper->daemon == NULL)
    {
        free(wrapper->page);
        free(wrapper);
        return NULL;
    }
    else
    {
        signal(SIGINT, handle_shutdown);
        signal(SIGTERM, handle_shutdown);

        return wrapper;
    }
}

static void delete_daemon_wrapper(DaemonWrapper *wrapper)
{
    if(wrapper != NULL)
    {
        MHD_stop_daemon(wrapper->daemon);
        free(wrapper->page);
        free(wrapper);
    }
}

static int run_main_loop(void)
{
    /* Loop until termination request was received */
    while(!terminated)
        sleep(1);

    return 0;
}

int run_foreground_process(int port)
{
    DaemonWrapper *wrapper = create_daemon_wrapper(port);

    if(wrapper == NULL)
    {
        fprintf(stderr, "Cannot start HTTP service!\n");
        return 1;
    }
    else
    {
        int exit_status = run_main_loop();
        delete_daemon_wrapper(wrapper);
        return exit_status;
    }
}

typedef struct
{
    int port;
    DaemonWrapper *wrapper;
}
DaemonConfig;

static int init_http_service(void *data)
{
    DaemonConfig *config = (DaemonConfig*)data;
    config->wrapper = create_daemon_wrapper(config->port);

    return (config->wrapper != NULL);
}

static int run_http_service(void *data)
{
    return run_main_loop();
}

DaemonStatus run_daemon(int port, const char *pid_file)
{
    DaemonConfig config;
    config.port = port;

    DaemonStatus exit_status = daemonize(pid_file, &config, init_http_service, run_http_service);
    if(exit_status != STATUS_INIT_SUCCESS)
        print_daemon_status(exit_status, stderr);

    return exit_status;
}

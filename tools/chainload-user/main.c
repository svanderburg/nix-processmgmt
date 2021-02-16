#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    if(argc < 3)
    {
        printf("Usage: %s username command [args]\n", argv[0]);
        return 1;
    }
    else
    {
        char *username = argv[1];

        /* Query password entry for the user */
        struct passwd *pwentry = getpwnam(username);

        if(pwentry == NULL)
        {
            fprintf(stderr, "Cannot find password entry for user: %s\n", username);
            return 1;
        }

        /* Change user permissions to the requested user */
        if(setgid(pwentry->pw_gid) == 0 && setuid(pwentry->pw_uid) == 0)
        {
            /* Exec into the requested process */
            char **cmd_argv = argv + 2;
            execvp(cmd_argv[0], cmd_argv);
            fprintf(stderr, "Cannot execute command: %s\n", cmd_argv[0]);
            return 1;
        }
        else
        {
            fprintf(stderr, "Cannot change into user: %s with corresponding group!\n", username);
            return 1;
        }
    }
}

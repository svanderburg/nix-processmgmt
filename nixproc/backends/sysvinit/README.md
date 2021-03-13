A Nix and sysvinit-based process management framework
=====================================================
This sub project contains a function abstraction that makes it possible to
generate sysvinit scripts with Nix. With this function it is possible to easily
manage *process deployments* -- Nix takes care of deploying the executable in
isolation in the Nix store, and the sysvinit script is used to manage the
lifecycle of the process.

Advantages of this approach:
* Works on any Linux system with the Nix package manager installed
* Can be used for unprivileged process deployments
* No additional process dependencies required -- Nix arranges all package
  dependencies, and that is all you need.

Usage
=====
This sub project has a variety of use cases.

Composing the createSystemVInitScript function
----------------------------------------------
To construct sysvinit scripts, you must first compose the
`createSystemVInitScript` function and provide it some global settings.
These global settings apply to all sysvinit scripts that are generated with it.

The following partial Nix expression shows how to compose this function with
the most common settings:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  createSystemVInitScript = import ./create-sysvinit-script.nix {
    inherit (stdenv) stdenv writeTextFile daemon;
    inherit runtimeDir tmpDir forceDisableUserChange;

    initFunctions = import ./init-functions.nix {
      basePackages = [ pkgs.coreutils pkgs.gnused pkgs.inetutils pkgs.gnugrep pkgs.sysvinit ];
      inherit (pkgs) stdenv;
      inherit runtimeDir;
    };

    createCredentials = import ./create-credentials.nix {
      inherit (pkgs) stdenv;
    };
  };
in
...
```

In the above Nix code fragment, we provide the following global configuration
settings:

* We need to provide a number of mandatory package dependencies, such as
  `stdenv`, `writeTextFile` and `daemon`.
* `runtimeDir` specifies the location where all PID files reside
* `tmpDir` specifies the location of the temp directory
* `forceDisableUserChange` globally disables user switches. For production
  environments, this should be disabled so that processes can run more securely
  as an unprivileged user. For development environments it may be useful to
  enable this feature so that you manage all processes without having super user
  privileges.
* The `initFunctions` parameter refers to a function invocation that deploys
  a package with the `init-functions` script. This script provides standard
  LSB functionality to manage processes.
* The `createCredentials` composes the function that can be used to configure
  a Dysnomia configuration file so that users and groups can be created on
  activation and discarded on deactivation.

In addition to the common settings shown above, there are also a number of
unconventional parameters. For common use scenarios, the default values suffice.
You only need to adjust them in special circumstances:

* `initialInstructions` specify the global initial instructions added to any
sysvinit script.
* `startDaemon` specifies the command-line instruction to start a daemon.
* `startProcessAsDaemon` specifies the command-line instruction to start a
  foreground process as a daemon.
* `startDaemon` specifies the command-line instruction to stop a daemon.
* `reloadDaemon` specifies the command-line instruction to reload a daemon.
* `evaluateCommand` specifies the command-line instruction that displays the
  status of the previously executed shell instruction.
* `statusCommand` specifies the command that retrieves the status of the daemon
* `restartActivity` specifies the implementation of the restart activity, that
  is common to all process-oriented sysvinit scripts.
* `supportedRunLevels` referts to a list that iterates all supported runlevels.
* `minSequence` specifies the minimum start sequence number.
* `maxSequence` specifies the maximum start sequence number.

Creating a sysvinit script
--------------------------
After composing the `createSystemVInitScript` function, we can write Nix
expressions that build sysvinit scripts.

### Specifying activities

The following Nix expression is a straight forward example demonstrating how we
can manage the Nginx web server:

```nix
{createSystemVInitScript, nginx, configFile, stateDir}:

createSystemVInitScript {
  name = "nginx";
  description = "Nginx";
  activities = {
    start = ''
      mkdir -p ${stateDir}/logs
      log_info_msg "Starting Nginx..."
      loadproc ${nginx}/bin/nginx -c ${configFile} -p ${stateDir}
      evaluate_retval
    '';
    stop = ''
      log_info_msg "Stopping Nginx..."
      killproc ${nginx}/bin/nginx
      evaluate_retval
    '';
    reload = ''
      log_info_msg "Reloading Nginx..."
      killproc ${nginx}/bin/nginx -HUP
      evaluate_retval
    '';
    restart = ''
      $0 stop
      sleep 1
      $0 start
    '';
    status = "statusproc ${nginx}/bin/nginx";
  };
  runlevels = [ 3 4 5 ];
}
```

The above Nix expression composes a sysvinit script to manage the life-cycle of
the Nginx server:

* The `name` parameter specifies the name of the sysvinit script
* The `description` specifies the description field shown in the meta
  information section.
* The `activities` parameter refers to an attribute set that specifies the
  implementation of each activity in bash code.
* The `runlevels` parameter specifies in which runlevels we want to start this
  script. It will automatically compose symlinks with the appropriate start
  sequence numbers in rc.d directories for the corresponding runlevels. An
  implication is that this function will automatically compose stop rc.d
  symlinks for the remaining runlevels.
  It will stop sysvinit scripts in exactly the opposite of the start order.

### Specifying instructions

Many sysvinit scripts implement activities that consist of a description line,
followed by a command, followed by displaying the status, e.g.:

```bash
log_info_msg "Starting Nginx..."
loadproc ${nginx}/bin/nginx -c ${configFile} -p ${stateDir}
evaluate_retval
```

It is possible to reduce this boilerplate code by using the instructions
facility:

```nix
{createSystemVInitScript, nginx, configFile, stateDir}:

createSystemVInitScript {
  name = "nginx";
  description = "Nginx";
  instructions = {
    start = {
      activity = "Starting";
      instruction = ''
        mkdir -p ${stateDir}/logs
        loadproc ${nginx}/bin/nginx -c ${configFile} -p ${stateDir}
      '';
    };
    stop = {
      activity = "Stopping";
      instruction = "killproc ${nginx}/bin/nginx";
    };
    reload = {
      activity = "Reloading";
      instruction = "killproc ${nginx}/bin/nginx -HUP";
    };
  };
  activities = {
    status = "statusproc ${nginx}/bin/nginx";
  };
  runlevels = [ 3 4 5 ];
}
```

In the above Nix expression we have replaced the `start`, `stop`, and `reload`
reload activities, with `instructions`. For these instructions, the description
line is automatically derived from the `description` parameter and augmented with
the instruction displaying the status.

### Specifying daemons to manage

It is possible to reduce the amount of boilerplate code even further --
in many scenarios we want to manage a process. The kind of activities that you
need are typically the same -- `start`, `stop`, `reload` (if applicable),
`status` and `restart`:

```nix
{createSystemVInitScript, nginx, configFile, stateDir}:

createSystemVInitScript {
  name = "nginx";
  description = "Nginx";
  initialize = ''
    mkdir -p ${stateDir}/logs
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile "-p" stateDir ];
  runlevels = [ 3 4 5 ];
}
```

In the above example, we do not specify any activities or instructions.
Instead, we specify the `process` we want to run and the command-line
instructions (`args`). From these properties, the generator will automatically
generate all relevant activities.

### Managing foreground processes

```nix
{createSystemVInitScript, port ? 5000}:

let
  webapp = (import ./webapp {}).package;
in
createSystemVInitScript {
  name = "webapp";
  process = "${webapp}/lib/node_modules/webapp/app.js";
  processIsDaemon = false;
  runlevels = [ 3 4 5 ];
  environment = {
    PORT = port;
  };
}
```

By default, sysvinit scripts expect processes to daemonize -- a process forks
another process that keeps running in the background and then the parent process
terminates. Most common system software, e.g. web servers, DBMS servers,
provides this kind of functionality.

Application software, however, that are typically implemented in more
"higher-level languages" than C, do not have this ability out of the box.

It is also possible to invoke libslack's
[daemon](http://www.libslack.org/daemon/) command to let a foreground process
daemonize -- when setting `processIsDaemon` to `false` (the default is: `true`),
the generator will automatically invoke the `daemon` command to accomplish this.

The `environment` parameter can be used to set additional environment variables.
In the above example, it is used to specify to which TCP port the process should
bind to.

### Specifying process dependencies

Processes may also communicate with other processes by using some kind of IPC
mechanism, such as Unix domain sockets. In such cases, a process might depend on
the activation of another process.

For example, the `nginx` server could act as a reverse proxy for the `webapp`.
This means that the `webapp` process should be activated first, otherwise users
might get a 502 bad gateway error.

We can augment the Nginx reverse proxy with a dependency parameter:

```nix
{createSystemVInitScript, nginx, configFile, stateDir, webapp}:

createSystemVInitScript {
  name = "nginx";
  description = "Nginx";
  initialize = ''
    mkdir -p ${stateDir}/logs
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile "-p" stateDir ];
  runlevels = [ 3 4 5 ];
  dependencies = [ webapp ];
}
```

The above example passed the `webapp` process as a dependency (through the
`dependencies` parameter) to the Nginx process. The generator makes sure that
the Nginx process gets a higher start sequence number and a lower stop sequence
number than the `webapp` process, ensuring that it starts in the right order
and stops in the reverse order.

### Managing multiple process instances

In addition to deploying single instances of processes, it is also possible to
have multiple instances of processes. For example, the Nginx reverse proxy can
forward incoming requests to multiple instances of the `webapp`.

sysvinit scripts use PID files to control daemons. Normally, PID files have the
same name as the executable. When running multiple instances, we must make sure
that every instance gets a unique PID, otherwise all instances might get
killed.

We can adjust the Nix expression of `webapp` with an `instanceName` parameter:

```nix
{createSystemVInitScript}:
{instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}", port ? 5000}:

let
  webapp = (import ./webapp {}).package;
in
createSystemVInitScript {
  inherit instanceName;

  process = "${webapp}/lib/node_modules/webapp/app.js";
  processIsDaemon = false;
  runlevels = [ 3 4 5 ];
  environment = {
    PORT = port;
  };
}
```

In the above example, we define a nested function in which the outer function
header (first line) refers to configuration properties applying to all process
instances.

The inner function header (second line) refers to instance properties:
* `instanceSuffix` can be used to construct a unique name for each `webapp`
  instance called in a variable called `instanceName`.
* `port` is a parameter that specifies to which TCP port the webapp should
  listen to. This port value should be unique for each `webapp` instance.

The `instanceName` parameter instructs the sysvinit script generator to create
a unique PID file for each running instance making it possible to control
instances individually.

### Managing user credentials

When deploying processes as system administrator, it is typically
insecure/unsafe to spawn processes as a root user.

The following expression instructs the generator to run the `webapp` as a unique
unprivileged user:

```nix
{createSystemVInitScript}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = (import ./webapp {}).package;
in
createSystemVInitScript {
  inherit instanceName;

  process = "${webapp}/lib/node_modules/webapp/app.js";
  processIsDaemon = false;
  runlevels = [ 3 4 5 ];
  environment = {
    PORT = port;
  };
  user = instanceName;

  credentials = {
    groups = {
      "${instanceName}" = {};
    };
    users = {
      "${instanceName}" = {
        group = instanceName;
        description = "Webapp";
      };
    };
  };
}
```

In the above example, the `credentials` parameter generates a configuration file
that Dysnomia can use to create or discard groups and users. The `user` parameter
instructs the script to switch privileges to the given user.

### Disable user switching

For production deployments, switching user privileges is useful, but for
experimentation as an unprivileged user it is not.

It is also possible to globally disable user switching, by setting the 
`forceDisableUserChange` to `true` in the example that composes the
`createSystemVInitScript` function.

### Other settings

The `createSystemVInitScript` has a variety of other configuration properties
not shown here, such as:

* Specifying the `umask` for default file permissions
* Specifying the nice level of the process with `nice`
* Change the current working directory with `directory`
* Adding additional packages to the sysvinit script's PATH, via `paths`
* Removing generated sysvinit script activities with `removeActivities`

Deploying a collection of processes
-----------------------------------
We can use the `nixproc-sysvinit-switch` command to build and activate all
processes in a processes expression:

```bash
$ nixproc-sysvinit-switch processes.nix
```

The `nixproc-sysvinit-switch` command will activate the processes in the right
order (this means it will ensure that `webapp` gets activated before `nginx`).

If we have already deployed a collection of processes then it does a comparison
with the previous deployment, and only deactivates obsolete processes and
activates new processes:

```bash
$ nixproc-sysvinit-switch processes.nix
```

In the above case, `rcswitch` will only deactivate obsolete processes and
activate new processes, making redeployments significantly faster.

Running activities on a collection of processes
-----------------------------------------------
In addition to deploying a collection of processes or upgrading a collection of
processes, it is also possible to run a certain activity on all sysvinit
scripts in the last deployed Nix profile:

```bash
$ nixproc-sysvinit-runactivity status
```

The above command will show the statuses of all processes in the provided Nix
profile.

By default, `nixproc-sysvinit-runactivity` will examine scripts in start
activation order.

We can also specify that we want to examine all scripts in the reverse order.
This is particularly useful to stop all services without breaking process
dependencies:

```bash
$ nixproc-sysvinit-runactivity -r stop
```

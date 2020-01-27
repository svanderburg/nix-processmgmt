Nix-based process management framework
======================================
This repository contains a very experimental prototype implementation of a
operating system and process manager agnostic Nix-based process managed
framework that can be used to run multiple instances of services on a single
machine, using Nix to deliver and isolate all required package dependencies and
configuration files.

Features:
* It uses *simple conventions* to specify system configurations: function
  definitions (corresponding to constructors), function invocations (that
  compose running process instances from constructors) and Nix profiles (that
  assembles multiple process configurations into one package).
* The ability to deploy *multiple instances* of processes.
* Deploying processes/services as an *unprivileged* user.
* Operating system and process manager *agnostic* -- it can be used on any
  operating system that supports the Nix package manager and works with a
  variety of process managers.
* Advanced concepts and features, such as namespaces and cgroups, are not
  required.

Supported process managers
==========================
Currently, the following process managers are supported:

* `sysvinit`: sysvinit scripts, also known as [LSB Init scripts](https://wiki.debian.org/LSBInitScripts)
* `bsdrc`: BSD [rc scripts](https://www.freebsd.org/doc/en_US.ISO8859-1/articles/rc-scripting/index.html)
* `supervisord`: [supervisord](http://supervisord.org)
* `systemd`: [systemd](https://www.freedesktop.org/wiki/Software/systemd)
* `launchd`: [launchd](https://www.launchd.info)
* `cygrunsrv`: Cygwin's [cygrunsrv](http://web.mit.edu/cygwin/cygwin_v1.3.2/usr/doc/Cygwin/cygrunsrv.README)

Prerequisites
=============
To use this framework, you first need to install:

* [The Nix package manager](http://nixos.org/nix)
* [The Nixpkgs collection](http://nixos.org/nixpkgs)
* [Dysnomia](http://github.com/svanderburg/dysnomia), if you want to manage users and groups

Installation
============
First, make a Git clone of this repository.

The next step is installing the build tool:

```bash
$ cd tools
$ nix-env -f default.nix -iA build
```

Then, at least one tool that deploys a configuration for a supported process
manager must be installed.

For example, to work with sysvinit scripts, you must install:

```bash
$ nix-env -f default.nix -iA sysvinit
```

To work with a different process manager, you should replace `sysvinit` with
any of the supported process managers listed above.

Usage
=====
For each kind of process you need to write a Nix expression that constructs
its configuration from sources and its dependencies. This can be done in a
process manager-specific and a process manager-agnostic way.

Then you need to create a constructors and processes expression.

The processes expression can be used by a deploy tool that works with a
specific process manager.

Writing a process manager-specific process management configuration
-------------------------------------------------------------------
The following expression is an example of a configuration that deploys
a sysvinit script that can be used to control a simple web application
process that just returns a static HTML page:

```nix
{createSystemVInitScript, runtimeDir}:
{port, instanceSuffix ? ""}:

let
  webapp = import ../../webapp;
  instanceName = "webapp${instanceSuffix}";
in
createSystemVInitScript {
  name = instanceName;
  inherit instanceName;
  process = "${webapp}/bin/webapp";
  args = [ "-D" ];
  environment = {
    PORT = port;
    PID_FILE = "${runtimeDir}/${instanceName}.pid";
  };

  runlevels = [ 3 4 5 ];

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

A process expression defines a nested function:

* The outer function (first line) allows properties to be configured that apply
  to all process instances, such as the the function that constructs sysvinit
  scripts (`createSystemVInitScript`) and the `runtimeDir` in which PID files
  are stored (on most systems this defaults to: `/var/run`).
* The inner function (second line) refers to all instance specific parameters.
  To allow multiple instances to co-exist, instance parameters must be
  configured in such a way that they no longer conflict. For example, if we
  assign two unique TCP `port` numbers and we append the process name with a
  unique suffix, we can run two instances of the web application at the same
  time.

In the body, we invoke the `createSystemVInitScript` function to declaratively
construct a sysvinit script:

* The `process` parameter specifies which process should be managed. From this
  parameter, the generator will automatically derive `start`, `stop`, `restart`
  and `reload` activities.
* The `args` parameter specifies the command line parameters propagated to the
  process. The `-D` parameter specifies that the webapp process should run in
  daemon mode (i.e. the process spawns another process that keeps running in
  the background and then terminates immediately).
* The `environment` attribute set defines all environment variables that the
  webapp process needs -- `PORT` is used to specify the TCP port it should
  listen to and `PID_FILE` specifies the path to the PID file that stores
  the process ID (PID) of the daemon process
* To allow multiple processes to co-exist, we must make sure that each has
  a unique PID file name. We can use the `instanceName` parameter to specify
  what name this PID file should have. By default, it gets the same name as
  the process name.
* The `runlevels` parameter specifies in which run levels the process should
  be started (in the above example: 3, 4, and 5. It will automatically
  configure the init system to stop the process in the other runlevels:
  0, 1, 2, and 6.
* It is also typically not recommended to run a service as root user. The
  `credentials` attribute specifies which group and user account need to be
  created. The `user` parameter specifies as which user the process needs to
  run at.

The `createSystemVInitScript` function support many more parameters than
described in the example above. For example, it is also possible to directly
specify how activities should be implemented.

It can also be used to specify dependencies on other sysvinit scripts -- the
system will automatically derive the sequence numbers so that they are activated
and deactivated in the right order.

In addition to sysvinit, there are also functions that can be used to create
configurations for the other supported process managers, e.g.
`createSystemdUnit`, `createSupervisordProgram`, `createBSDRCScript`. Check
the implementations in `nixproc/create-managed-process` for more information.

Writing a process manager-agnostic process management configuration
-------------------------------------------------------------------
This repository contains generator functions for a variety of process managers.
What you will notice is that they require parameters that looks quite similar.

When it is desired to target multiple process managers, it is also possible to
write a process manager-agnostic configuration from which a variety of
configurations can be generated.

This expression is a process manager-agnostic version of the previous example:

```nix
{createManagedProcess, runtimeDir}:
{port, instanceSuffix ? ""}:

let
  webapp = import ../../webapp;
  instanceName = "webapp${instanceSuffix}";
in
createManagedProcess {
  name = instanceName;
  description = "Simple web application";
  inherit instanceName;

  # This expression can both run in foreground or daemon mode.
  # The process manager can pick which mode it prefers.
  process = "${webapp}/bin/webapp";
  daemonArgs = [ "-D" ];

  environment = {
    PORT = port;
    PID_FILE = "${runtimeDir}/${instanceName}.pid";
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

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
```

In the above example, we invoke `createManagedProcess` to construct a
configuration for a process manager. It captures similar properties that
are described in the sysvinit-specific configuration, as shown in the previous
example.

To allow it to target a variety of process managers, we must specify:

* How the process can be started in foreground mode. The `process`
  parameter gets translated to `foregroundProcess` and `daemon`. The former
  specifies how the service should be started as a foreground process and the
  latter how it should start as a daemon.
* The `daemonArgs` parameter specifies which command-line parameters the process
  should take

Under the hood, the `createManagedProcess` function invokes a generator function
which calls the corresponding process manager-specific create function.

The `createManagedProcess` abstraction function does not support all
functionality that the process manager-specific abstraction functions provide --
It only supports a common subset. To get non-standardized functionality working,
you can also define `overrides`, that augments the generated function parameters
with  process manager-specific parameters.

In the above example, we define an override to specify the `runlevels`. Runlevels
is a concept only supported by sysvinit scripts.

Writing a constructors expression
---------------------------------
As shown in the previous sections, a process configuration is a nested function.
To be able to deploy a certain process configuration, it needs to be composed
twice.

The common parameters (the outer function) are composed in a so-called
constructors expression, that has the following structure:

```nix
{ pkgs
, stateDir
, logDir
, runtimeDir
, tmpDir
, forceDisableUserChange
, processManager
}:

let
  createManagedProcess = import ../../nixproc/create-managed-process/agnostic/create-managed-process-universal.nix {
    inherit pkgs runtimeDir tmpDir forceDisableUserChange processManager;
  };
in
{
  webapp = import ./webapp.nix {
    inherit createManagedProcess runtimeDir;
  };

  nginxReverseProxy = import ./nginx-reverse-proxy.nix {
    inherit createManagedProcess stateDir logDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile nginx;
  };
}
```

The above Nix expression defines a function that takes common state
configuration parameters that applies to all services:

* `pkgs` refers to the Nixpkgs collection
* `stateDir` refers to the base directory where all variable data needs to be
  stored. The default on most systems is `/var`.
* `runtimeDir` refers to the base directory where all PID files are stored
* `tmpDir` refers to the base directory where all temp files are stored
* `forceDisableUserChange` can be used to globally switch of the creation of
  users and groups and changing users.
* `processManager` specifies which process manager we want to use (when it is
  desired to do process manager agnostic deployments).

In the body, the function returns an attribute set in which every value refers
to a constructor function that can be used to construct process instances.

The `webapp` attribute refers to a constructor function that can be used to
construct one or more running `webapp` processes. It takes the common parameters
that it requires as function arguments.

The constructors attribute facilitates multiple constructor functions.
`nginxReverseProxy` refers to a process configuration that launches the
[Nginx](http://nginx.com) HTTP server and configures it to act as a reverse
proxy for an arbitrary number of web application processes.

Writing a processes expression
------------------------------
The processes Nix expression makes it possible to construct one or more
instances of processes:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
  };
in
rec {
  webapp1 = rec {
    port = 5000;
    dnsName = "webapp1.local";

    pkg = constructors.webapp {
      inherit port;
    };
  };

  webapp2 = rec {
    port = 5001;
    dnsName = "webapp2.local";

    pkg = constructors.webapp {
      inherit port;
    };
  };

  nginxReverseProxy = rec {
    port = 8080;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp1 webapp2 ];
      inherit port;
    } {};
  };
}
```

The above Nix expression is a function in which the parameters (again) specify
common state configuration parameters. It makes a reference the constructors
expression shown in the previous example.

The function body returns an attribute set that defines three process
instances:

* `webapp1` is a web application process that listens on TCP port 5000
* `webapp2` is a web application process that listens on TCP port 5001
* `nginxReverseProxy` is an Nginx server that forwards requests to the
  web application processes. If the virtual host is `webapp1.local` then the
  first `webapp1` process responds, if the virtual host is `webapp2.local` then
  the second process (`webapp2`) responds.

Building a process configurations profile
-----------------------------------------
We can build all required packages and generate all configuration artifacts for
a specific process manager by running the following command:

```bash
$ nixproc-build --process-manager sysvinit processes.nix
result/
```

The above command generates sysvinit scripts and start and stop symlinks to
ensure that the webapp processes are started before the Nginx reverse proxy.

The `--process-manager` parameter can be changed to generate configuration files
for different process managers. For example, if we would use
`--process-manager systemd` then the resulting Nix profile contains a collection
of systemd unit configuration files.

Deploying a process configurations profile
------------------------------------------
In addition to generating configuration files that can be consumed by a process
manager, we can also invoke the process manager to deploy all process defined in
our process Nix expression.

The following command automatically starts all sysvinit scripts (and stop all
obsolete sysvinit scripts, in case of an upgrade):

```bash
$ nixproc-sysvinit-switch processes.nix
```

Consult the help pages of the corresponding process manager specific tools to
get a better understanding on how they work.

Changing the state directories
------------------------------
By default, the all processes use the `/var` directory as a base directory to
store all state. This location can be adjusted by using the `--state-dir`
parameter.

The following command deploys all process instances and stores their state in
`/home/sander/var`:

```bash
$ nixproc-sysvinit-switch --state-dir /home/sander/var processes.nix
```

Similarly, it is also possible to adjust the base locations of the runtime
files, log files and temp files, if desired.

Deploying process instances as an unprivileged user
---------------------------------------------------
It is also possible to do unprivileged user deployments. Unfortunately,
unprivileged users cannot create new groups and/or users or change permissions
of running processes.

This can be globally disabled with the `--force-disable-user-change` parameter.

The following command makes it possible to deploy all processes as an
unprivileged user:

```bash
$ nixproc-sysvinit-switch --state-dir /home/sander/var --force-disable-user-change processes.nix
```

Examples
========
This repository contains three example systems, that can be found in the
`examples/` folder:

* `webapps-sysvinit` is a processes configuration set using the example `webapp`
  process described in this README, with `nginx` reverse proxies. The
  configuration is specifically written to use sysvinit as a process manager.
* `webapps-agnostic` is the same as the previous example, but using a process
  manager agnostic configuration. It can be used to target all process managers
  that this toolset supports.
* `services-agnostic` is a process manager-agnostic configuration set of common
  system services: Apache HTTP server, MySQL, PostgreSQL and Apache Tomcat.

License
=======
The contents of this package is available under the same license as Nixpkgs --
the [MIT](https://opensource.org/licenses/MIT) license.

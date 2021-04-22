Nix-based process management framework
======================================
This repository contains a very experimental prototype implementation of an
operating system and process manager agnostic Nix-based process managed
framework that can be used to run multiple instances of services on a single
machine, using Nix to deliver and isolate all required package dependencies and
configuration files.

Features:
* It uses *simple conventions* to specify system configurations: function
  definitions (corresponding to constructors), function invocations (that
  compose running process instances from constructors) and Nix profiles (that
  assembles multiple process configurations into one package).
* It identifies process dependencies, so that a process manager can ensure that
  processes are activated and deactivated in the right order.
* The ability to deploy *multiple instances* of the same process, by making
  conflicting resources configurable.
* Deploying processes/services as an *unprivileged user*.
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
* `s6-rc`: [s6-rc](https://skarnet.org/software/s6-rc) for managing services
  supervised by [s6](https://skarnet.org/software/s6)

It can also work with the following solutions that are technically not
categorized as process managers (but can still be used as such):

* `docker`: [Docker](https://docker.com) is technically more than just a process
  manager, but by sharing the host's network, Nix store, and bind mounting
  relevant state directories, it can also serve as a process manager with
  similar functionality as the others described above.
* `disnix`: Technically [Disnix](https://github.com/svanderburg/disnix) is not
  a process manager but it is flexible enough to start daemons and arrange
  activation ordering. This target backend is not designed for managing
  production systems, but it is quite convenient as a simple solution
  for experimentation that is supported on most UNIX-like systems.

Prerequisites
=============
To use this framework, you first need to install:

* [The Nix package manager](http://nixos.org/nix)
* [The Nixpkgs collection](http://nixos.org/nixpkgs)
* [Dysnomia](http://github.com/svanderburg/dysnomia), if you want to manage users and groups
* To use the ID assigner tool: `nixproc-id-assign` (for port numbers, UIDs and
  GIDs), you need a recent development version of
  [Dynamic Disnix](https://github.com/svanderburg/dydisnix)

Installation
============
First, make a Git clone of this repository.

The next step is installing the common tools:

```bash
$ cd tools
$ nix-env -f default.nix -iA common
```

Then, at least one tool that deploys a configuration for a supported process
manager must be installed.

For example, to work with sysvinit scripts, you must install:

```bash
$ nix-env -f default.nix -iA sysvinit
```

To work with a different process manager, you should replace `sysvinit` with
any of the supported process managers listed in the previous section. For
example, to use utilities to generate and deploy `systemd` configurations, you
should run:

```bash
$ nix-env -f default.nix -iA systemd
```

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
process (with an embedded HTTP server) that just returns a static HTML page:

```nix
{createSystemVInitScript, tmpDir}:

let
  webapp = import ../../webapp;
  user = "webapp";
  group = "webapp";
in
createSystemVInitScript {
  name = "webapp";
  process = "${webapp}/bin/webapp";
  args = [ "-D" ];
  environment = {
    PORT = 5000;
    PID_FILE = "${tmpDir}/webapp.pid";
  };

  runlevels = [ 3 4 5 ];

  inherit user;

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "Webapp";
      };
    };
  };
}
```

A process expression defines a function:

* The function header (first line) allows build-time dependencies and common
  configuration properties to be configured, such as the the function that
  constructs sysvinit scripts (`createSystemVInitScript`) and the `runtimeDir`
  in which PID files are stored (on most systems this defaults to: `/var/run`).

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
* The `runlevels` parameter specifies in which run levels the process should
  be started (in the above example: 3, 4, and 5. It will automatically
  configure the init system to stop the process in the other runlevels:
  0, 1, 2, and 6.
* It is also typically not recommended to run a service as root user. The
  `credentials` attribute specifies which group and user account need to be
  created. The `user` parameter specifies the user the process needs to
  run as.

The `createSystemVInitScript` function supports many more parameters than
described in the example above. For example, it is also possible to directly
specify how activities should be implemented.

It can also be used to specify `dependencies` on other sysvinit scripts -- the
system will automatically derive the sequence numbers so that they are activated
and deactivated in the right order.

In addition to sysvinit, there are also functions that can be used to create
configurations for the other supported process managers, e.g.
`createSystemdUnit`, `createSupervisordProgram`, `createBSDRCScript`. Check
the implementations in `nixproc/backends` for more information.

Writing an instantiatable process configuration
-----------------------------------------------
The example shown earlier only allows you to deploy a single instance of the
`webapp` process. A second instance cannot co-exist because it will allocate
conflicting resources, such as the TCP port it binds to and the PID file.
These resources can only be assigned once.

It is also possible to revise the example to allow multiple process instances
to co-exist, by making conflicting resources configurable.

An instantiatable process expression defines a nested function:

```nix
{createSystemVInitScript, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../webapp;
in
createSystemVInitScript {
  inherit instanceName;
  process = "${webapp}/bin/webapp";
  args = [ "-D" ];
  environment = {
    PORT = port;
    PID_FILE = "${tmpDir}/${instanceName}.pid";
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
* The process should have a unique name to identify it with. If no `name`
  parameter was specified, then the `name` will automatically correspond to
  `instanceName`.
* We must make sure that each has a unique PID file name. We can use the
  `instanceName` parameter to specify what name this PID file should have.
  By default, the PID file gets the same name as the process instance name.
* To also allocate a unique user and group for the process. We are using the
  `instanceName` parameter as a unique user and group name.

Writing a process manager-agnostic process management configuration
-------------------------------------------------------------------
This repository contains generator functions for a variety of process managers.
What you will notice is that they accept parameters that look quite similar.

When it is desired to target multiple process managers, it is also possible to
write a process manager-agnostic configuration from which configuration files
can be generated for all supported process management backends.

This is a process manager-agnostic version of the previous example:

```nix
{createManagedProcess, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../webapp;
in
createManagedProcess {
  inherit instanceName;
  description = "Simple web application";

  # This expression can both run in foreground or daemon mode.
  # The process manager can pick which mode it prefers.
  process = "${webapp}/bin/webapp";
  daemonArgs = [ "-D" ];

  environment = {
    PORT = port;
    PID_FILE = "${tmpDir}/${instanceName}.pid";
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
configuration for any process manager supported by this framework. It captures
similar properties that are described in the sysvinit-specific configuration,
as shown in the previous example.

To allow the specification to target a variety of process managers, we must
specify:

* How the process can be started in foreground and daemon mode. The `process`
  parameter gets translated to `foregroundProcess` and `daemon`. The former
  specifies how the service should be started as a foreground process and the
  latter how it should start as a daemon.
* The `daemonArgs` parameter specifies which command-line parameters the process
  should take when it is supposed to run as a daemon.

Under the hood, the `createManagedProcess` function invokes a generator function
that calls the corresponding process manager-specific create function.

The `createManagedProcess` abstraction function does not support all
functionality that the process manager-specific abstraction functions provide --
it only supports a common subset. To get non-standardized functionality working,
you can also define `overrides`, that augment the generated function parameters
with process manager-specific parameters.

In the above example, we define an override to specify the `runlevels`. Runlevels
is a concept only supported by sysvinit scripts.

Defining process manager-specific overrides
-------------------------------------------
As described in the previous section, the `createManagedProcess` abstraction only
works with high-level concepts that are easily generalizable to all kinds of
process managers.

The attribute set of parameters passed to the `createManagedProcess` function
gets translated to an attribute set of parameters for the corresponding
process manager-specific abstraction functions, e.g. `createSystemVInitScript`,
`createSupervisordProgram`, `createSystemdService` etc.

We can change the content of the generated attribute set, allowing you to get
access to any property of a process manager backend including properties for
which the `createManagedProcess` function does provide any high-level concepts.

An override can be be an attribute set that simply overrides or augments the
process manager-specific parameter attribute set:

```nix
{createManagedProcess, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../webapp;
in
createManagedProcess {
  inherit instanceName;
  description = "Simple web application";

  # This expression can both run in foreground or daemon mode.
  # The process manager can pick which mode it prefers.
  process = "${webapp}/bin/webapp";
  daemonArgs = [ "-D" ];

  environment = {
    PORT = port;
    PID_FILE = "${tmpDir}/${instanceName}.pid";
  };

  overrides = {
    sysvinit.runlevels = [ 3 4 5 ];
    systemd = {
      Service.Restart = "always";
    };
  };
}
```

In the above example case, we use an override to define in which runlevels the
service should start (a sysvinit specific concept), and when systemd is used,
the service gets restarted automatically when it stops (which is not a universal
property all process managers support, but systemd does).

It is also possible to write an override as a function which is more powerful --
you can also delete and augment existing parameters with additional information,
if desired:

```nix
{createManagedProcess, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../webapp;
in
createManagedProcess {
  inherit instanceName;
  description = "Simple web application";

  # This expression can both run in foreground or daemon mode.
  # The process manager can pick which mode it prefers.
  process = "${webapp}/bin/webapp";
  daemonArgs = [ "-D" ];

  environment = {
    PORT = port;
    PID_FILE = "${tmpDir}/${instanceName}.pid";
  };

  overrides = {
    sysvinit.runlevels = [ 3 4 5 ];
    systemd = systemdArgs: systemdArgs // {
      Service = systemdArgs.Service // {
        ExecStart = "${systemdArgs.Service.ExecStart} -D";
        Type = "forking";
      };
    };
  };
}
```

In the above example, I modify the generated systemd arguments in such a way
that the service runs in daemon mode and it is managed as a daemon (by default,
the systemd generator prefers to work with foreground processes).

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
  createManagedProcess = import ../../nixproc/create-managed-process/universal/create-managed-process-universal.nix {
    inherit pkgs runtimeDir tmpDir forceDisableUserChange processManager;
  };
in
{
  webapp = import ./webapp.nix {
    inherit createManagedProcess tmpDir;
  };

  nginx = import ./nginx-reverse-proxy.nix {
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

  nginx = rec {
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
  the second process (`webapp2`) responds. Nginx listens on TCP port 8080.

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

To still allow unprivileged user deployments, user configuration and switching
can be globally disabled with the `--force-disable-user-change` parameter.
Then the `credentials` and `user` switching parameters are ignored.

The following command makes it possible to deploy all processes as an
unprivileged user:

```bash
$ nixproc-sysvinit-switch --state-dir /home/sander/var --force-disable-user-change processes.nix
```

Undeploying the system
----------------------
It may also be desired to completely undeploy a system when it is no longer
needed. The following command completely undeploys all previously deployed
processes:

```bash
$ nixproc-sysvinit-switch --undeploy
```

Assigning unique IDs to services
--------------------------------
As explained earlier, to ensure that multiple process instances have no
conflicts, they require unique process instance parameters.

One catagory of process parameters are unique numeric IDs, such as port
numbers, UIDs and GIDs. It is possible to manually assign them, but this process
can also be automated.

The following configuration file is an ID resources configuration file
(`idresources.nix`) that defines pools of numeric ID resources:

```nix
rec {
  webappPorts = {
    min = 5000;
    max = 6000;
  };

  nginxPorts = {
    min = 8080;
    max = 9000;
  };

  uids = {
    min = 2000;
    max = 3000;
  };

  gids = uids;
}
```

The above ID resources configuration defines the following resources:

* The `webappPorts` is a pool of unique TCP port number assigned to the `webapp`
  processes shown in the previous examples. These are unique numbers between
  5000 and 6000.
* The `nginxPorts` is a pool of unique TCP port numbers assigned to `nginx`
  instances. These are unique numbers between 8080 and 9000.
* `uids` specifies the range of unique user IDs (UIDs) between 2000 and 3000.
* `gids` specifies the range of unique group IDs (GIDs). They are identical to
  the `uids`.

To use automatic ID assignments, the processes model (`processes.nix`) can be
augmented as follows:

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
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager ids;
  };
in
rec {
  webapp1 = rec {
    port = ids.webappPorts.webapp1 or 0;
    dnsName = "webapp1.local";

    pkg = constructors.webapp {
      inherit port;
    };

    requiresUniqueIdsFor = [ "uids" "gids" "webappPorts" ];
  };
}
```

The above process model has the following changes:

* Every process instance is annotated with a `requiresUniqueIdsFor` attribute
  that specifies for which resources the process instances requires unique IDs
* In the beginning of the expression we have imported the generated `ids.nix`
  expression that contains all generated unique ID assignments. If the file
  does not exists, an empty attribute set is returned.
* Every process instance consumes the unique IDs from the `ids` attribute set,
  as opposed to using hardcoded values. The `webapp1` service uses a auto
  generated port assignment. If no such assignment exists, it defaults to 0
  to allow the processes model evaluation not to fail, for the initial IDs
  assignment.

To automatically generate the ID assignments from an ID resources configuration
and processes model, you can run:

```bash
$ nixproc-id-assign --id-resources idresources.nix --output-file ids.nix processes.nix
```

The above command automatically assigns IDs to all processes that require them and writes
the output result to the `ids.nix` file. This file may look as follows:

```nix
{
  "ids" = {
    "gids" = {
      "webapp" = 2001;
    };
    "nginxPorts" = {
    };
    "uids" = {
      "webapp" = 2001;
    };
    "webappPorts" = {
      "webapp" = 5000;
    };
  };
  "lastAssignments" = {
    "gids" = 2001;
    "uids" = 2001;
    "webappPorts" = 5000;
  };
}
```

The above expression defines two attributes:
* The `ids` attribute contains for each resource a mapping between process
  instance and a unique ID.
* The `lastAssignments` attribute memorizes the last assigned ID for each
  resource to prevent reassigning the same IDs, until the maximum ID limit has
  been reached.

When updating the processes model, you can run the following command to update
the ID assignments:

```bash
$ nixproc-id-assign --id-resources idresources.nix --ids ids.nix --output-file ids.nix processes.nix
```

The difference between the above command invocation and the previous is that we
take our existing ID assignment in account -- for processes that were already
deployed previously we retain their ID assignments to prevent unnecessary
redeployments.

In addition to port numbers, we can also assign and retain unique UIDs and GIDs
per process instance. We can use a similar strategy to port numbers to propagate 
these values as parameters, but a more convenient way is to instrument the
`createCredentials` function -- the above `processes.nix` expression propagates
the entire `ids` attribute set as a parameter to the constructors.

The constructors expression indirectly composes the `createCredentials` function
as follows:

```nix
{pkgs, ids ? {}, ...}:

{
  createCredentials = import ../../create-credentials {
    inherit (pkgs) stdenv;
    inherit ids;
  };

  ...
}
```

The `ids` attribute set is propagated to the function that composes the
`createCredentials` function. As a result, it will automatically assign the UIDs
and GIDs in the `ids.nix` expression when the user configures a user or group
with a name that exists in the `uids` and `gids` resource pools.

To make these UIDs and GIDs assignments go smoothly, it is recommended to give
a process the same process name, instance name, user and group names.

The `nixproc-id-assign` tool is basically just a wrapper around the
`dydisnix-id-assign` tool and internally converts a processes model to a Disnix
services model.

Writing integration tests
-------------------------
As explained in the introduction, the framework supports all kinds of
interesting features producing all kinds of variants of the same service, such
as multiple process managers, multiple process instances, unprivileged
deployments etc.

Although a service can support all these variants, writing a model does not
guarantee that it will always work under all circumstances. The Nix process
management framework supports code reuse, but does not facilitate a write once,
run anywhere approach.

To validate a service, we can use a test driver built on top of the NixOS test
driver that can be used to test multiple variants of a service.

The following Nix expression is an example of a test suite for the advanced
variant of the webapp example with two Nginx reverse proxies:

```nix
{ pkgs, testService, processManagers, profiles }:

testService {
  inherit processManagers profiles;

  exprFile = ./processes-advanced.nix;

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "nginx" || instanceName == "nginx2")
      (pkgs.lib.concatMapStrings (webapp: ''
        machine.succeed(
            "curl --fail -H 'Host: ${webapp.dnsName}' http://localhost:${toString instance.port} | grep ': ${toString webapp.port}'"
        )
      '') instance.webapps);

}
```

The above Nix expression invokes `testService` with the following parameters:
* `processManagers` refers to a list of names of all the process managers that
  should be tested.
* `profiles` refers to a list of configuration profiles that should be tested.
  Currently, it supports `privileged` for privileged deployments, and
  `unprivileged` for unprivileged deployments in an unprivileged user's home
  directory, without changing user permissions.
* The `exprFile` parameter refers to a processes model of a system, such as
  `processes-advanced.nix` capturing the properties of a system that consists
  of multiple `webapp` and `nginx` instances, as described earlier.
* The `readiness` parameter refers to a function that does a readiness check
  for each process instance. In the above example, it checks whether each service
  is actually listening on the required TCP port.
* The `tests` parameter refers to a function that executes tests for each
  process instance. In the above example, it ignores all but the `nginx`
  instances, because explicitly testing a `webapp` instance is a redundant
  operation. For each `nginx` instance, it checks whether all `webapp` instances
  can be reached from it, by running the `curl` command.

The `readiness` and `tests` functions take `instanceName` as a parameter that
identifies the process instance in the processes model, and `instance` that
refers to the attribute set containing its configuration.

It is also possible to refer to global configuration parameters:
* `stateDir`. The directory in which state files are stored (typically `/var`
  for privileged deployments)
* `runtimeDir`: The directory in which runtime files are stored.
* `forceDisableUserChange`. Indicates whether to disable user changes (for
  unprivileged deployments) or not.

In addition to writing tests that work on instance level, it is also possible
to write tests on system level, with the following parameters (not shown in the
example):

* `initialTests`: instructions that run right after deploying the system, but
  before the `readiness` checks, and instance-level `tests`.
* `postTests`: instructions that run after the instance-level `tests`.

The above parameters refer to functions that also accept global configuration
parameters, and `processes` that can refer to the entire processes model.

The Nix expression above is not self-contained. It is a function definition
that needs to be invoked with all the process managers and profiles that we
want to test for.

We can compose tests in the following Nix expression:

```nix
{ nixpkgs ? <nixpkgs>
, system ? builtins.currentSystem
, processManagers ? [ "supervisord" "sysvinit" "systemd" "docker" "disnix" "s6-rc" ]
, profiles ? [ "privileged" "unprivileged" ]
}:

let
  pkgs = import nixpkgs { inherit system; };

  testService = import ../../nixproc/test-driver/universal.nix {
    inherit nixpkgs system;
  };
in
{

  nginx-reverse-proxy-hostbased = import ./nginx-reverse-proxy-hostbased {
    inherit pkgs processManagers profiles testService;
  };

  docker = import ./docker {
    inherit pkgs processManagers profiles testService;
  };

  ...
}
```

The above partial Nix expression (`default.nix`) invokes the function defined in
the previous Nix expression that resides in the `nginx-reverse-proxy-hostbased`
directory and propagates all required parameters. It also composes other test
cases, such as `docker`.

The parameters of the composition expression allows you to globally configure
the service variants:

* `processManagers` allows you to select the process managers you want to test
  for.
* `profiles` allows you to select the configuration profiles.

With the following command, we can test our system as a privileged user, using
`systemd` as a process manager:

```bash
$ nix-build -A nginx-reverse-proxy-hostbased.privileged.systemd
```

we can also run the same test, but then as an unprivileged user:

```bash
$ nix-build -A nginx-reverse-proxy-hostbased.unprivileged.systemd
```

In addition to `systemd`, any configured process manager can be used that works
with the NixOS test driver. The following command runs a privileged test of the
same service for `sysvinit`:

```bash
$ nix-build -A nginx-reverse-proxy-hostbased.privileged.sysvinit
```

Although the test driver makes it possible to test all possible variants of a
service, doing so may be very expensive. In the above example, we have two
configuration profiles and six process managers, resulting in twelve possible
variants of the same service.

To get a reasonable level of confidence, it typically suffices to implement the
following strategy:
* Pick two process managers: one that prefers foreground processes
  (e.g. `supervisord`) and one that prefers daemons (e.g. `sysvinit`).
  This is the most significant difference (from a configuration perspective)
  between all these different process managers.
* If a service supports multiple configuration variants, and multiple
  instances, then create a processes model that concurrently deploys all
  these variants.

Implementing the above strategy only requires you to test four variants,
providing a high degree of certainty that it will work with all other process
managers as well.

Since the test driver is built on top of the NixOS test driver (that is Linux
based), we cannot use the test driver to test service variants on different
operating systems. `launchd`, `bsdrc` and `cygrunsrv` can only be tested
manually for now.

Integration with Disnix
-----------------------
In addition to the fact that this toolset provides a `disnix` backend that
facilitates universal and easy local deployment, any process model is basically
a sub set of a Disnix services model.

By augmenting all processes in a processes model with a number of additional
properties, we can turn it into a fully functional Disnix services model:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, distribution, invDistribution
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  processManager = "sysvinit";

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
  };
in
rec {
  webapp1 = rec {
    name = "webapp1";
    port = 5000;
    dnsName = "webapp1.local";

    pkg = constructors.webapp {
      inherit port;
    };

    type = "sysvinit-script";
  };

  webapp2 = rec {
    name = "webapp2";
    port = 5001;
    dnsName = "webapp2.local";

    pkg = constructors.webapp {
      inherit port;
    };

    type = "sysvinit-script";
  };

  nginx = rec {
    name = "nginx";
    port = 8080;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp1 webapp2 ];
      inherit port;
    } {};

    type = "sysvinit-script";
  };
}
```

In the above Disnix services, the following changes were made:

* The `processManager` is hardcoded to `sysvinit`.
* Every process has been turned into a service by augmenting the following
  properties: `name` corresponds to the key in attribute set, and `type`
  to the Dysnomia plugin that manages its lifecycle. To manage the lifecycle
  of a `sysvinit-script` we can use the Dysnomia plugin with the same name.

Dysnomia, the toolset that manages the lifecycles of services, has plugins for
the same process managers that this toolset supports. With a few small
modifications, we can make a universal services model that allows us to pick
any process management solution that this toolset supports based on the on the
value of the `processManager` parameter:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, distribution, invDistribution
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? "sysvinit"
}:

let
  processType = import ../../nixproc/derive-dysnomia-process-type.nix {
    inherit processManager;
  };

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
  };
in
rec {
  webapp1 = rec {
    name = "webapp1";
    port = 5000;
    dnsName = "webapp1.local";

    pkg = constructors.webapp {
      inherit port;
    };

    type = processType;
  };

  webapp2 = rec {
    name = "webapp2";
    port = 5001;
    dnsName = "webapp2.local";

    pkg = constructors.webapp {
      inherit port;
    };

    type = processType;
  };

  nginx = rec {
    name = "nginx";
    port = 8080;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp1 webapp2 ];
      inherit port;
    } {};

    type = processType;
  };
}
```

In the services model shown above, we have re-introduced the `processManager`
parameter. We use a convenience function that derives the `processType` from
the selected `processManager`. For example, `sysvinit` maps to `sysvinit-script`,
`systemd` to `systemd-unit`, `supervisord` to `supervisord-program` etc.
All the service's `type` attributes bind to the derived `processType`.

There is also a special case -- when `processManager` is `null`, then the
selected type will be `managed-process`, that works with process
manager-agnostic JSON configuration files that get converted to a
process-manager specific configuration on the target machines (with
the `nixproc-generate-config` tool) and deployed as such.

`managed-process` is useful when we want to deploy services in a network of
machines running various opeating and process managers by using the same
deployment specifications.

By combining the services model shown above with an infrastructure model, and
distribution model, we can deploy the system to a network of machines:

```bash
$ disnix-env -s services.nix -i infrastructure.nix -d distribution.nix
```

the following command allows us to pick a different process manager, such as
`systemd`:

```bash
$ disnix-env -s services.nix -i infrastructure.nix -d distribution.nix --extra-params '{ processManager = "systemd"; }'
```

Building a multi-process Docker container
-----------------------------------------
Another useful integration solution is generating multi-process Docker images.
We can build a Docker image that launches multiple processes managed by a
process manager that is both compatible with Linux and Docker.

To construct such as an image, we can evaluate a Nix expression (e.g.
`default.nix`) that looks as follows:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
}:

let
  createMultiProcessImage = import ../../nixproc/create-image-from-steps/create-multi-process-image-universal.nix {
    inherit pkgs;
  };
in
createMultiProcessImage {
  name = "multiprocess";
  tag = "test";

  exprFile = ../webapps-agnostic/processes.nix;
  processManager = "supervisord"; # sysvinit, disnix, s6-rc are also valid options

  interactive = true; # the default option
  manpages = false; # the default option
  forceDisableUserChange = false; # the default option
}
```

In the above expression, we evaluate the `createMultiProcessImage` function
with the following parameters:

* The `name` refers to the name of the image, whereas `tag` refers to a Docker
  image version tag.
* The `exprFile` refers to a processes expression file that declares running
  process instances (as shown earlier)
* The `processManager` parameter allows you to pick a process manager.
  Currently, all the options shown above are supported.
* We can also specify whether we want to use the container interactively
  with the `interactive` parameter (which defaults to: `true`). When
  this setting has been enabled, a `.bashrc` will be configured to make
  the bash shell usable, and a number of additional packages will be installed
  for file and process management operations.
* We can also optionally install `man` in the container so that you can access
  manual pages. By default, it is disabled
* It is also possible to adjust the state settings in the processes model.
  With `forceDisableUserChange` we can disable user creation and user
  switching. It is also possible to control the other state variables, such
  as `stateDir`.

The function shown above is basically a thin wrapper around the
`dockerTools.buildImage` function in Nixpkgs and accepts the same parameters,
with a number of process management parameters added to it.

The corresponding deployment procedure of an image is also similar to ordinary
single root process images. For example, to build the image you can run:

```bash
$ nix-build
```

and load it into Docker as follows:

```bash
$ docker load -i result
```

We can deploy a container instance from the image in interactive mode as
follows:

```bash
$ docker run --name mycontainer --rm --network host -it multiprocess:test
```

When interactive mode has been enabled, you should be able to "connect" to
a container in which you can execute shell commands, for example to control
the life-cycle of the sub processes:

```bash
$ docker exec -it mycontainer /bin/bash
$ ps aux
```

Building a mutable multi-process Docker container
-------------------------------------------------
A big drawback of the multi-process container deployed in the previous
section is that its deployment is *immutable* -- the deployment is done from an
image that configures all process instances, but when it is desired to change
the configuration, a new image needs to be generated and the container must
be discarded and redeployed from that new image.

It is also possible to deploy *mutable* multi-process containers in which the
configuration of the managed system can be updated without the need to bring
the container down.

The following Nix expression (`default.nix`) can be used to construct a mutable
multi-process image:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
}:

let
  createMutableMultiProcessImage = import ../../nixproc/create-image-from-steps/create-mutable-multi-process-image-universal.nix {
    inherit pkgs;
  };
in
createMutableMultiProcessImage {
  name = "multiprocess";
  tag = "test";

  exprFile = ./processes.nix;
  idResourcesFile = ./idresources.nix;
  idsFile = ./ids.nix;
  processManager = "supervisord";

  interactive = true;
  manpages = false;
  forceDisableUserChange = false;
  bootstrap = true;
}
```

The Nix expression shown above invokes the `createMutableMultiProcessImage`
function that has a similar interface to the immutable variant shown in the
previous section, with the following differences:

* The `exprFile` is also used for specifying the process model to deploy from,
  but a notable difference is that for mutable containers this model is copied
  into the container and deployed from within the container. If the `exprFile`
  parameter is omitted, an empty configuration is deployed.
* To make deploying process models model possible that also use
  `nixproc-id-assign` to automatically assign unique numeric IDs, the
  `idResourcesFile` and `idsFile` parameters can be used to copy these models
  into the container as well. These parameters are not mandatory.
* As a container entry point, a *bootstrap* script is executed, that on first
  deployment, uses the Nix package manager, and the corresponding
  `nixproc-*-switch` tool to deploy the system.
* The `bootstrap` parameter allows you to disable the bootstrap entry point.
  By default, it is enabled.

To make deployments in mutable containers possible, the processes model should
not contain any references to files on the local file system (with the exception
of the `ids.nix` model that should reside in the same base directory).

The following process model (`processes.nix`) eliminates local file dependencies
by using `builtins.fetchGit` to obtain the Nix process management framework:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
, webappMode ? null
}:

let
  nix-processmgmt = builtins.fetchGit {
    url = https://github.com/svanderburg/nix-processmgmt.git;
    ref = "master";
  };

  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  sharedConstructors = import "${nix-processmgmt}/examples/services-agnostic/constructors.nix" {
    inherit pkgs stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange processManager ids;
  };

  constructors = import "${nix-processmgmt}/examples/webapps-agnostic/constructors.nix" {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager webappMode ids;
  };
in
rec {
  webapp = rec {
    port = ids.webappPorts.webapp or 0;
    dnsName = "webapp.local";

    pkg = constructors.webapp {
      inherit port;
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  nginx = rec {
    port = ids.nginxPorts.nginx or 0;

    pkg = sharedConstructors.nginxReverseProxyHostBased {
      webapps = [ webapp ];
      inherit port;
    } {};

    requiresUniqueIdsFor = [ "nginxPorts" "uids" "gids" ];
  };
}
```

To deploy a mutable multi-process image container, we can run the following
command to build the image:

```bash
$ nix-build
```

and load it into Docker as follows:

```bash
$ docker load -i result
```

We can deploy a container instance from the image in interactive mode as
follows:

```bash
$ docker run --name mycontainer --rm --network host -it multiprocess:test
```

On first startup, the container will carry out a bootstrap procedure that uses
the Nix process management framework to deploy all the processes in the
processes model.

When the deployment of the system is complete, we can "connect" to the container
instance as follows:

```bash
$ docker exec -it mycontainer /bin/bash
```

In the container, we can edit the process model (to for example, add a new
`webapp` instance):

```bash
$ mcedit /etc/nixproc/processes.nix
```

and redeploy the new configuration with the following command:

```bash
$ nixproc-supervisord-switch
```

then the new configuration should become active without the need to restart the
container. Moreover, when stopping the container and starting it again, the last
deployed configuration should become active again.

Building a Nix-enabled Docker container
---------------------------------------
One of the interesting aspects of a mutable multi-process image is that it
provides a fully featured Nix installation in a container that can be used
to deploy arbitrary Nix packages.

It is also possible to generate an image whose only purpose is to provide a
working Nix installation:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
}:

let
  createNixImage = import ../../nixproc/create-image-from-steps/create-nix-image.nix {
    inherit pkgs;
  };
in
createNixImage {
  name = "foobar";
  tag = "test";
}
```

Examples
========
This repository contains a number of example systems, that can be found in the
`examples/` folder:

* `webapps-sysvinit` is a processes configuration set using the example `webapp`
  process described in this README, with `nginx` reverse proxies. The
  configuration is specifically written to use sysvinit as a process manager.
* `webapps-agnostic` is the same as the previous example, but using a process
  manager agnostic configuration. It can be used to target all process managers
  that this toolset supports.
* `services-agnostic` is a process manager-agnostic configuration set of
  additional system services used for tests, such as docker, supervisord, and
  nginx
* `service-containers-agnostic` extends the previous examples with configuration
  files so that these system services can be deployed as Disnix containers --
  services in which other services can be hosted.
* `multi-process-image` is an example demonstrating how to construct a Docker
  image that concurrently runs all processes described in the `webapps-agnostic`
  example managed by a process management solution of choice.

The
[Nix process management services](https://github.com/svanderburg/nix-processmgmt-services)
repository contains a collection of commonly used services that can be managed
with the Nix process management framework.

Troubleshooting
===============
This section contains a number of known problems and their resolutions.

Inspecting log files
--------------------
When a service does not work as expected, then it is typically desired to check
the logs of the corresponding service. Although many process management concepts
are standardized by this framework, logging is not standardized at all.

This section contains some pointers for some of the process management solution
targets that are currently implemented.

### systemd and docker

Some process/service managers have their own logging facility. For example,
`systemd` provides `journalctl`, and `docker` provides `docker logs`. They
automatically capture the output (the `stdout` and `stderr`) of foreground
processes.

### sysvinit, bsdrc, disnix

For process management solutions that rely on processes that deamonize on their
own (`sysvinit`, `bsdrc` and `disnix`), you need to consult the logs that are
managed by the services themselves (a daemon typically detaches itself from the
`stdout` and `stderr`. As a result, a process manager cannot do it).

Services that only provide foreground processes are automatically daemonized
with the `daemon` command by these three backends. By default, the `daemon`
command will capture their outputs in log files with a `nixproc-` prefix in
the log directory. On a production system, such a log file could be:
`/var/log/nixproc-myservice.log` for services that are started as root users
and `/tmp/nixproc-myservice.log` for services that are started as unprivileged
users.

### supervisord

`supervisord` will (if no settings have been configured) store log files
(capturing the `stdout` and `stderr` of each process) in the temp directory
(typically `/tmp` or the value of the `TMPDIR` environment variable).

### cygrunsrv

By default, the `stderr` of `cygrunsrv` managed services are captured in the log
folder. An example could be: `/var/log/myservice.log`.

### s6-rc

If there is no logging configured, any output produced by supervised processes
is redirected to the `s6-svscan` process that supervises the entire service
dependency tree.

In this framework, by default, `longrun` services are automatically configured
in such a way that there is also logging companion service that captures its
output.

The output captured by the logging companion services are stored in the `s6-log`
sub folder in the log directory (which is typically
`/var/log/s6-log/<service name>` on most systems).

License
=======
The contents of this package is available under the same license as Nixpkgs --
the [MIT](https://opensource.org/licenses/MIT) license.

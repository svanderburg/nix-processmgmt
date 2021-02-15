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
process that just returns a static HTML page:

```nix
{createSystemVInitScript, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../webapp;
in
createSystemVInitScript {
  name = instanceName;
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
the implementations in `nixproc/backends` for more information.

Writing a process manager-agnostic process management configuration
-------------------------------------------------------------------
This repository contains generator functions for a variety of process managers.
What you will notice is that they require parameters that look quite similar.

When it is desired to target multiple process managers, it is also possible to
write a process manager-agnostic configuration from which a variety of
configurations can be generated.

This expression is a process manager-agnostic version of the previous example:

```nix
{createManagedProcess, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../webapp;
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
  name = instanceName;
  description = "Simple web application";
  inherit instanceName;

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
  name = instanceName;
  description = "Simple web application";
  inherit instanceName;

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

```
$ docker exec -it mycontainer /bin/bash
$ ps aux
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

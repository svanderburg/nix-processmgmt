{ generateProcessFun, processManager, stdenv }:

{
# A name that identifies the process instance
name
# A more human-readable description of the process
, description ? name
# Shell commands that specify how the state should be initialized
, initialize ? ""
# Path to a process to execute (both in foreground and daemon mode)
, process ? null
# Generic command-line parameters propagated to the process
, args ? []
# The executable that needs to run to start the process is daemon mode
, daemon ? process
# Extra arguments appended to args when the process runs in daemon mode
, daemonExtraArgs ? []
# Command-line arguments propagated to the daemon
, daemonArgs ? (args ++ daemonExtraArgs)
# A name that uniquely identifies each process instance. It is used to generate a unique PID file.
, instanceName ? null
# Path to a PID file that the system should use to manage the process. If null, it will use a default path.
, pidFile ? null
# The executable that needs to run to start the process in foreground mode
, foregroundProcess ? process
# Extra arguments appended to args when the process runs in foreground mode
, foregroundProcessExtraArgs ? []
# Command-line arguments propagated to the foreground process
, foregroundProcessArgs ? (args ++ foregroundProcessExtraArgs)
# Specifies which packages need to be in the PATH
, path ? []
# An attribute set specifying arbitrary environment variables
, environment ? {}
# If not null, the current working directory will be changed before executing any activities
, directory ? null
# If not null, the umask will be changed before executing any activities
, umask ? null
# If not null, the nice level be changed before executing any activities
, nice ? null
# Specifies as which user the process should run. If null, the user privileges will not be changed.
, user ? null
# Dependencies on other processes. Typically, this specification is used to derive the activation order.
, dependencies ? []
# Specifies which groups and users that need to be created.
, credentials ? {}
# Specifies process manager specific properties that augmented to the generated function parameters
, overrides ? {}
}@properties:

let
  createAgnosticConfig = import ./create-agnostic-config.nix {
    inherit stdenv;
  };
in
if processManager == null then createAgnosticConfig properties
else generateProcessFun {
  inherit name description initialize daemon daemonArgs instanceName pidFile foregroundProcess foregroundProcessArgs path environment directory umask nice user dependencies credentials;
  overrides = if builtins.hasAttr processManager overrides then builtins.getAttr processManager overrides else {};
}

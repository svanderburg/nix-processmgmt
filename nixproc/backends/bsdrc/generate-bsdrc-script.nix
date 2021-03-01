{ createBSDRCScript, lib }:

{ name
, description
, initialize
, daemon
, daemonArgs
, instanceName
, pidFile
, foregroundProcess
, foregroundProcessArgs
, path
, environment
, directory
, umask
, nice
, user
, dependencies
, credentials
, overrides
, postInstall
}:

# TODO: umask

let
  generatedTargetSpecificArgs = {
    inherit name environment path directory nice dependencies;
    inherit user instanceName credentials postInstall;

    command = if daemon != null then daemon else foregroundProcess;
    commandIsDaemon = daemon != null;
    commandArgs = if daemon != null then daemonArgs else foregroundProcessArgs;
  } // lib.optionalAttrs (pidFile != null) {
    inherit pidFile;
  } // lib.optionalAttrs (initialize != "") {
    commands.start.pre = initialize;
  };

  targetSpecificArgs =
    if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
    else lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in
createBSDRCScript targetSpecificArgs

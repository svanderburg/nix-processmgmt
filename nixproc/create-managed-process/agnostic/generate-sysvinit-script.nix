{ createSystemVInitScript, stdenv }:

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

let
  generatedTargetSpecificArgs = {
    inherit name description path environment directory umask nice dependencies credentials;
    inherit instanceName initialize user postInstall;

    process = if daemon != null then daemon else foregroundProcess;
    processIsDaemon = daemon != null;
    args = if daemon != null then daemonArgs else foregroundProcessArgs;
  } // stdenv.lib.optionalAttrs (pidFile != null) {
    inherit pidFile;
  };

  targetSpecificArgs =
    if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
    else stdenv.lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in
createSystemVInitScript targetSpecificArgs

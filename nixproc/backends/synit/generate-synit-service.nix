{ lib, createSynitDaemon, undaemonize }:

{ name, description, initialize, daemon, daemonArgs, instanceName, pidFile
, foregroundProcess, foregroundProcessArgs, path, environment, directory, umask
, nice, user, dependencies, credentials, overrides, postInstall }:

let
  generatedTargetSpecificArgs = {
    inherit name description environment directory path dependencies initialize
      user;

    process = if foregroundProcess != null then
      foregroundProcess
    else
      (lib.getExe undaemonize);

    args = map toString (if foregroundProcess != null then
      foregroundProcessArgs
    else
      [ daemon ] ++ daemonArgs);
  };

  targetSpecificArgs = if builtins.isFunction overrides then
    overrides generatedTargetSpecificArgs
  else
    lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in createSynitDaemon targetSpecificArgs

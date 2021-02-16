{ createSupervisordProgram, stdenv, writeTextFile, runtimeDir, forceDisableUserChange }:

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
  generateForegroundProxy = import ../util/generate-foreground-proxy.nix {
    inherit stdenv writeTextFile;
  };

  chainLoadUser = if initialize == "" || forceDisableUserChange then null
    else user;

  command = if foregroundProcess != null then
    (if initialize == ""
      then foregroundProcess
      else generateForegroundProxy ({
        user = chainLoadUser;
        wrapDaemon = false;
        executable = foregroundProcess;
        inherit name initialize runtimeDir stdenv;
      } // stdenv.lib.optionalAttrs (instanceName != null) {
        inherit instanceName;
      } // stdenv.lib.optionalAttrs (pidFile != null) {
        inherit pidFile;
      })) + " ${stdenv.lib.escapeShellArgs foregroundProcessArgs}"
    else (generateForegroundProxy ({
      wrapDaemon = true;
      user = chainLoadUser;
      executable = daemon;
      inherit name initialize runtimeDir stdenv;
    } // stdenv.lib.optionalAttrs (instanceName != null) {
      inherit instanceName;
    } // stdenv.lib.optionalAttrs (pidFile != null) {
      inherit pidFile;
    })) + " ${stdenv.lib.escapeShellArgs daemonArgs}";

  generatedTargetSpecificArgs = {
    inherit name command path environment dependencies credentials postInstall;
  } // stdenv.lib.optionalAttrs (umask != null) {
    inherit umask;
  } // stdenv.lib.optionalAttrs (nice != null) {
    inherit nice;
  } // stdenv.lib.optionalAttrs (pidFile != null) {
    inherit pidFile;
  } // stdenv.lib.optionalAttrs (user != null && chainLoadUser == null) {
    inherit user;
  };

  targetSpecificArgs =
    if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
    else stdenv.lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in
createSupervisordProgram targetSpecificArgs

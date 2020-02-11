{ createSupervisordProgram, stdenv, writeTextFile, runtimeDir }:

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
}:

let
  generateForegroundWrapper = import ./generate-foreground-wrapper.nix {
    inherit stdenv writeTextFile;
  };

  command = if foregroundProcess != null then
    (if initialize == ""
      then foregroundProcess
      else generateForegroundWrapper ({
        wrapDaemon = false;
        executable = foregroundProcess;
        inherit name initialize runtimeDir stdenv;
      } // stdenv.lib.optionalAttrs (instanceName != null) {
        inherit instanceName;
      } // stdenv.lib.optionalAttrs (pidFile != null) {
        inherit pidFile;
      })) + " ${stdenv.lib.escapeShellArgs foregroundProcessArgs}"
    else (generateForegroundWrapper ({
      wrapDaemon = true;
      executable = daemon;
      inherit name initialize runtimeDir stdenv;
    } // stdenv.lib.optionalAttrs (instanceName != null) {
      inherit instanceName;
    } // stdenv.lib.optionalAttrs (pidFile != null) {
      inherit pidFile;
    })) + " ${stdenv.lib.escapeShellArgs daemonArgs}";
in
createSupervisordProgram (stdenv.lib.recursiveUpdate ({
  inherit name command path environment dependencies credentials;
} // stdenv.lib.optionalAttrs (umask != null) {
  inherit umask;
} // stdenv.lib.optionalAttrs (nice != null) {
  inherit nice;
} // stdenv.lib.optionalAttrs (pidFile != null) {
  inherit pidFile;
} // stdenv.lib.optionalAttrs (user != null) {
  inherit user;
}) overrides)

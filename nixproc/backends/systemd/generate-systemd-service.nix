{ createSystemdService, stdenv, lib, writeTextFile }:

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
  generatePreStartScript = import ../util/generate-prestart-script.nix {
    inherit stdenv writeTextFile;
  };

  generatedTargetSpecificArgs = {
    inherit name path environment dependencies credentials postInstall;

    Unit = {
      Description = description;
    };
    Service = {
      ExecStart = if foregroundProcess != null
        then "${foregroundProcess} ${lib.escapeShellArgs foregroundProcessArgs}"
        else "${daemon} ${lib.escapeShellArgs daemonArgs}";
      Type = if foregroundProcess != null then "simple" else "forking";
    } // lib.optionalAttrs (initialize != "") {
      ExecStartPre = lib.optionalString (user != null) "+" + generatePreStartScript {
        inherit name initialize;
      };
    } // lib.optionalAttrs (directory != null) {
      WorkingDirectory = directory;
    } // lib.optionalAttrs (umask != null) {
      UMask = umask;
    } // lib.optionalAttrs (nice != null) {
      Nice = nice;
    } // lib.optionalAttrs (foregroundProcess == null && pidFile != null) {
      PIDFile = pidFile;
    } // lib.optionalAttrs (user != null) {
      User = user;
    };
  };

  targetSpecificArgs =
    if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
    else lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in
createSystemdService targetSpecificArgs

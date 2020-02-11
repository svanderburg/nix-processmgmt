{ createSystemdService, stdenv, writeTextFile }:

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
  generatePreStartScript = import ./generate-prestart-script.nix {
    inherit stdenv writeTextFile;
  };
in
createSystemdService (stdenv.lib.recursiveUpdate {
  inherit name path environment dependencies credentials;

  Unit = {
    Description = description;
  };
  Service = {
    ExecStart = if foregroundProcess != null then "${foregroundProcess} ${stdenv.lib.escapeShellArgs foregroundProcessArgs}" else "${daemon} ${stdenv.lib.escapeShellArgs daemonArgs}";
    Type = if foregroundProcess != null then "simple" else "forking";
  } // stdenv.lib.optionalAttrs (initialize != "") {
    ExecStartPre = stdenv.lib.optionalString (user != null) "+" + generatePreStartScript {
      inherit name initialize;
    };
  } // stdenv.lib.optionalAttrs (directory != null) {
    WorkingDirectory = directory;
  } // stdenv.lib.optionalAttrs (umask != null) {
    UMask = umask;
  } // stdenv.lib.optionalAttrs (nice != null) {
    Nice = nice;
  } // stdenv.lib.optionalAttrs (foregroundProcess == null && pidFile != null) {
    PIDFile = pidFile;
  } // stdenv.lib.optionalAttrs (user != null) {
    User = user;
  };
} overrides)

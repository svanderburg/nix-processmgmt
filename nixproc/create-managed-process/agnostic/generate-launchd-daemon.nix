{ createLaunchdDaemon
, stdenv
, writeTextFile
, runtimeDir ? "/var/run"
}:

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

  Program = if foregroundProcess != null then
    if initialize == "" then foregroundProcess
    else generateForegroundWrapper ({
      wrapDaemon = false;
      executable = foregroundProcess;
      inherit name initialize runtimeDir stdenv;
    } // stdenv.lib.optionalAttrs (instanceName != null) {
      inherit instanceName;
    } // stdenv.lib.optionalAttrs (pidFile != null) {
      inherit pidFile;
    })
  else generateForegroundWrapper ({
    wrapDaemon = true;
    executable = daemon;
    inherit name initialize runtimeDir stdenv;
  } // stdenv.lib.optionalAttrs (instanceName != null) {
    inherit instanceName;
  } // stdenv.lib.optionalAttrs (pidFile != null) {
    inherit pidFile;
  });
  ProgramArguments = [ Program ] ++ (if foregroundProcess != null then foregroundProcessArgs else daemonArgs);

  daemonConfig = createLaunchdDaemon (stdenv.lib.recursiveUpdate ({
    inherit name credentials Program;
  } // stdenv.lib.optionalAttrs (ProgramArguments != [ Program ]) {
    inherit ProgramArguments;
  } // stdenv.lib.optionalAttrs (environment != {}) {
    EnvironmentVariables = environment;
  } // stdenv.lib.optionalAttrs (path != []) {
    inherit path;
  } // stdenv.lib.optionalAttrs (directory != null) {
    WorkingDirectory = directory;
  } // stdenv.lib.optionalAttrs (umask != null) {
    Umask = umask;
  } // stdenv.lib.optionalAttrs (nice != null) {
    Nice = nice;
  } // stdenv.lib.optionalAttrs (user != null) {
    UserName = user;
  }) overrides);
in
if dependencies == [] then daemonConfig else
builtins.trace "WARNING: dependencies have been specified for process: ${name}, but launchd has no notion of process dependencies. Proper activation ordering cannot be guaranteed!" daemonConfig

{ createLaunchdDaemon
, stdenv
, lib
, writeTextFile
, runtimeDir ? "/var/run"
, forceDisableUserChange
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
, postInstall
}:

let
  generateForegroundProxy = import ../util/generate-foreground-proxy.nix {
    inherit stdenv lib writeTextFile;
  };

  chainLoadUser = if initialize == "" || forceDisableUserChange then null
    else user;

  Program = if foregroundProcess != null then
    if initialize == "" then foregroundProcess
    else generateForegroundProxy ({
      wrapDaemon = false;
      user = chainLoadUser;
      executable = foregroundProcess;
      inherit name initialize runtimeDir stdenv;
    } // lib.optionalAttrs (instanceName != null) {
      inherit instanceName;
    } // lib.optionalAttrs (pidFile != null) {
      inherit pidFile;
    })
  else generateForegroundProxy ({
    wrapDaemon = true;
    user = chainLoadUser;
    executable = daemon;
    inherit name initialize runtimeDir stdenv;
  } // lib.optionalAttrs (instanceName != null) {
    inherit instanceName;
  } // lib.optionalAttrs (pidFile != null) {
    inherit pidFile;
  });
  ProgramArguments = [ Program ] ++ (if foregroundProcess != null then foregroundProcessArgs else daemonArgs);

  generatedTargetSpecificArgs = {
    inherit name credentials postInstall Program;
  } // lib.optionalAttrs (ProgramArguments != [ Program ]) {
    inherit ProgramArguments;
  } // lib.optionalAttrs (environment != {}) {
    EnvironmentVariables = environment;
  } // lib.optionalAttrs (path != []) {
    inherit path;
  } // lib.optionalAttrs (directory != null) {
    WorkingDirectory = directory;
  } // lib.optionalAttrs (umask != null) {
    Umask = umask;
  } // lib.optionalAttrs (nice != null) {
    Nice = nice;
  } // lib.optionalAttrs (user != null && chainLoadUser == null) {
    UserName = user;
  };

  targetSpecificArgs =
    if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
    else lib.recursiveUpdate generatedTargetSpecificArgs overrides;

  daemonConfig = createLaunchdDaemon targetSpecificArgs;
in
if dependencies == [] then daemonConfig else
builtins.trace "WARNING: dependencies have been specified for process: ${name}, but launchd has no notion of process dependencies. Proper activation ordering cannot be guaranteed!" daemonConfig

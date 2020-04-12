{ createCygrunsrvParams
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
, postInstall
}:

# TODO: credentials
# TODO: directory unused
# TODO: umask unused
# TODO: nice unused
# TODO: user unused

let
  generateForegroundWrapper = import ./generate-foreground-wrapper.nix {
    inherit stdenv writeTextFile;
  };
in
createCygrunsrvParams (stdenv.lib.recursiveUpdate ({
  inherit name environment dependencies postInstall;

  environmentPath = path;

  path = if foregroundProcess != null then
    if initialize == "" then foregroundProcess
    else generateForegroundWrapper {
      wrapDaemon = false;
      executable = foregroundProcess;
      inherit name initialize runtimeDir pidFile stdenv;
    }
  else generateForegroundWrapper {
    wrapDaemon = true;
    executable = daemon;
    inherit name initialize runtimeDir pidFile stdenv;
  };

  args = if foregroundProcess != null then foregroundProcessArgs else daemonArgs;
}) overrides)

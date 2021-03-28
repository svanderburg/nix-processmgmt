{ createCygrunsrvParams
, stdenv
, lib
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

let
  generateForegroundProxy = import ../util/generate-foreground-proxy.nix {
    inherit stdenv lib writeTextFile;
  };

  generatedTargetSpecificArgs = {
    inherit name environment dependencies postInstall;

    environmentPath = path;

    path = if foregroundProcess != null then
      if initialize == "" && nice == null && directory == null && umask == null then foregroundProcess
      else generateForegroundProxy {
        wrapDaemon = false;
        executable = foregroundProcess;
        inherit name initialize runtimeDir pidFile nice directory umask stdenv;
      }
    else generateForegroundProxy {
      wrapDaemon = true;
      executable = daemon;
      inherit name initialize runtimeDir pidFile nice stdenv;
    };

    args = if foregroundProcess != null then foregroundProcessArgs else daemonArgs;
  };

  targetSpecificArgs =
    if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
    else lib.recursiveUpdate generatedTargetSpecificArgs overrides;

  cygrunSrvConfig = createCygrunsrvParams targetSpecificArgs;
in
if credentials == {} && user == null then cygrunSrvConfig else
builtins.trace "It is not possible to create any users for cygrunsrv services. Cygwin automatically converts Windows users to UNIX users" cygrunSrvConfig

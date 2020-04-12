{ createBSDRCScript, stdenv }:

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

# TODO: umask

createBSDRCScript (stdenv.lib.recursiveUpdate ({
  inherit name environment path directory nice dependencies;
  inherit user instanceName credentials postInstall;

  command = if daemon != null then daemon else foregroundProcess;
  commandIsDaemon = daemon != null;
  commandArgs = if daemon != null then daemonArgs else foregroundProcessArgs;

} // stdenv.lib.optionalAttrs (pidFile != null) {
  inherit pidFile;
} // stdenv.lib.optionalAttrs (initialize != "") {
  commands.start.pre = initialize;
}) overrides)

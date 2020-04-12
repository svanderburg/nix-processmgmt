{ createSystemVInitScript, stdenv }:

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

createSystemVInitScript (stdenv.lib.recursiveUpdate ({
  inherit name description path environment directory umask nice dependencies credentials;
  inherit instanceName initialize user postInstall;

  process = if daemon != null then daemon else foregroundProcess;
  processIsDaemon = daemon != null;
  args = if daemon != null then daemonArgs else foregroundProcessArgs;
} // stdenv.lib.optionalAttrs (pidFile != null) {
  inherit pidFile;
}) overrides)

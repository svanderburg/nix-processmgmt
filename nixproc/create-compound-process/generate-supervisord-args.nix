{ pkgs, system

, name
, compoundRuntimeDir
, compoundLogDir

, exprFile
, stateDir
, runtimeDir
, logDir
, cacheDir
, tmpDir
, forceDisableUserChange
, extraParams
}:

let
  profile = import ../create-managed-process/supervisord/build-supervisord-env.nix {
    inherit pkgs system exprFile stateDir runtimeDir cacheDir logDir tmpDir forceDisableUserChange extraParams;
  };

  pidFile = "${compoundRuntimeDir}/${name}.pid";
  logFile = "${compoundLogDir}/${name}.log";
in
{
  process = "${pkgs.pythonPackages.supervisor}/bin/supervisord";
  args = [ "--configuration" "${profile}/supervisord.conf" "--logfile" logFile ];
  daemonExtraArgs = [ "--pidfile" pidFile ];
  foregroundProcessExtraArgs = [ "--nodaemon" ];
  inherit pidFile;
}

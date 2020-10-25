{createManagedProcess, supervisor, runtimeDir, logDir}:
{instanceSuffix ? "", instanceName ? "supervisord${instanceSuffix}", initialize ? "", configFile, postInstall ? ""}:

let
  pidFile = "${runtimeDir}/${instanceName}.pid";
  logFile = "${logDir}/${instanceName}.log";
in
createManagedProcess {
  name = instanceName;
  inherit instanceName postInstall;
  initialize = ''
    mkdir -p ${logDir}
    ${initialize}
  '';
  process = "${supervisor}/bin/supervisord";
  args = [ "--configuration" configFile "--logfile" logFile "--pidfile" pidFile ];
  foregroundProcessExtraArgs = [ "--nodaemon" ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

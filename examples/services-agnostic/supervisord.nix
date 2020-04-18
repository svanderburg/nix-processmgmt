{createManagedProcess, supervisor, runtimeDir, logDir}:
{instanceSuffix ? "", initialize ? "", configFile, postInstall ? ""}:

let
  instanceName = "supervisord${instanceSuffix}";
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
  args = [ "--configuration" configFile "--logfile" logFile ];
  foregroundProcessExtraArgs = [ "--nodaemon" ];
  daemonExtraArgs = [ "--pidfile" pidFile ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

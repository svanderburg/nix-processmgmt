{createManagedProcess, tmpDir}:
{port, instanceSuffix ? ""}:

let
  webapp = import ../../webapp;
  instanceName = "webapp${instanceSuffix}";
  pidFile = "${tmpDir}/${instanceName}.pid";
in
createManagedProcess {
  name = instanceName;
  description = "Simple web application";
  inherit instanceName;

  # This expression only specifies how to run webapp in daemon mode
  daemon = "${webapp}/bin/webapp";
  daemonArgs = [ "-D" ];

  environment = {
    PORT = port;
    PID_FILE = pidFile;
  };

  inherit pidFile;

  user = instanceName;
  credentials = {
    groups = {
      "${instanceName}" = {};
    };
    users = {
      "${instanceName}" = {
        group = instanceName;
        description = "Webapp";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

{createManagedProcess, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../../../webapp;
in
createManagedProcess {
  description = "Simple web application";
  inherit instanceName;

  # This expression only specifies how to run the webapp in foreground mode
  foregroundProcess = "${webapp}/bin/webapp";

  environment = {
    PORT = port;
  };
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

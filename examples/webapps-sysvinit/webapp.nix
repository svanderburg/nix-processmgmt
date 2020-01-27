{createSystemVInitScript, runtimeDir}:
{port, instanceSuffix ? ""}:

let
  webapp = import ../../webapp;
  instanceName = "webapp${instanceSuffix}";
in
createSystemVInitScript {
  name = instanceName;
  inherit instanceName;
  process = "${webapp}/bin/webapp";
  args = [ "-D" ];
  environment = {
    PORT = port;
    PID_FILE = "${runtimeDir}/${instanceName}.pid";
  };

  runlevels = [ 3 4 5 ];

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
}

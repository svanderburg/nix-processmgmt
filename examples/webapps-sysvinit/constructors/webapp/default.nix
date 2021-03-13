{createSystemVInitScript, tmpDir}:
{port, instanceSuffix ? "", instanceName ? "webapp${instanceSuffix}"}:

let
  webapp = import ../../../../webapp;
in
createSystemVInitScript {
  inherit instanceName;

  process = "${webapp}/bin/webapp";
  args = [ "-D" ];
  environment = {
    PORT = port;
    PID_FILE = "${tmpDir}/${instanceName}.pid";
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

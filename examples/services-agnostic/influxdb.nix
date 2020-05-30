{createManagedProcess, influxdb}:
{instanceSuffix ? "", configFile, postInstall ? ""}:

let
  instanceName = "influxdb${instanceSuffix}";
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  name = instanceName;
  inherit instanceName postInstall;
  foregroundProcess = "${influxdb}/bin/influxd";
  args = [ "-config" configFile ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "InfluxDB user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

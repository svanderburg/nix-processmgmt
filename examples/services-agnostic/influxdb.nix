{createManagedProcess, influxdb, stateDir}:
{instanceSuffix ? "", instanceName ? "influxdb${instanceSuffix}", configFile, postInstall ? ""}:

let
  user = instanceName;
  group = instanceName;

  influxdbStateDir = "${stateDir}/lib/${instanceName}";
in
createManagedProcess {
  name = instanceName;
  inherit instanceName user postInstall;
  foregroundProcess = "${influxdb}/bin/influxd";
  args = [ "-config" configFile ];
  initialize = ''
    mkdir -p ${influxdbStateDir}
  '';

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        homeDir = influxdbStateDir;
        createHomeDir = true;
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

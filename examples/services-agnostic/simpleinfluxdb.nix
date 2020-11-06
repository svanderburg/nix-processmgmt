{createManagedProcess, influxdb, writeTextFile, stateDir}:
{instanceSuffix ? "", instanceName ? "influxdb${instanceSuffix}", rpcBindIP ? "127.0.0.1", rpcPort ? 8088, httpBindIP ? "", httpPort ? 8086, extraConfig ? "", postInstall ? ""}:

let
  influxdbStateDir = "${stateDir}/lib/${instanceName}";

  configFile = writeTextFile {
    name = "influxdb.conf";
    text = ''
      bind-address = "${rpcBindIP}:${toString rpcPort}"

      [meta]
      dir = "${influxdbStateDir}/meta"

      [data]
      dir = "${influxdbStateDir}/data"
      wal-dir = "${influxdbStateDir}/wal"

      [http]
      enabled = true
      bind-address = "${httpBindIP}:${toString httpPort}"

      ${extraConfig}
    '';
  };
in
import ./influxdb.nix {
  inherit createManagedProcess influxdb stateDir;
} {
  inherit instanceName configFile postInstall;
}

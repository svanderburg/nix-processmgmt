{influxdbConstructorFun, dysnomia}:
{instanceSuffix ? "", rpcBindIP ? "127.0.0.1", rpcPort ? 8088, httpBindIP ? "", httpPort ? 8086, extraConfig ? "", type}:

let
  pkg = influxdbConstructorFun {
    inherit instanceSuffix rpcBindIP rpcPort httpBindIP httpPort extraConfig;
    postInstall = ''
      # Add Dysnomia container configuration file for InfluxDB
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/influx-database${instanceSuffix} <<EOF
      httpPort=${toString httpPort}
      EOF

      # Copy the Dysnomia module that manages an InfluxDB database
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/influx-database $out/libexec/dysnomia
    '';
  };
in
rec {
  name = "influxdb${instanceSuffix}";
  inherit pkg type httpPort;
  providesContainer = "influx-database${instanceSuffix}";
}

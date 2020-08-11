{mysqlConstructorFun, dysnomia, runtimeDir}:
{port ? 3306, instanceSuffix ? "", instanceName ? "mysql${instanceSuffix}", containerName ? "mysql-database${instanceSuffix}", type}:

let
  mysqlSocket = "${runtimeDir}/${instanceName}/${instanceName}.sock";

  mysqlUsername = "root";

  pkg = mysqlConstructorFun {
    inherit port instanceName;
    postInstall = ''
      # Add Dysnomia container configuration file for MySQL database
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      mysqlPort=${toString port}
      mysqlUsername="${mysqlUsername}"
      mysqlPassword=
      mysqlSocket=${mysqlSocket}
      EOF

      # Copy the Dysnomia module that manages MySQL database
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/mysql-database $out/libexec/dysnomia
    '';
  };
in
rec {
  name = instanceName;
  mysqlPort = port;

  inherit pkg type mysqlSocket mysqlUsername;

  providesContainer = containerName;
}

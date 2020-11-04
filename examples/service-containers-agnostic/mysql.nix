{mysqlConstructorFun, dysnomia, runtimeDir}:

{ instanceSuffix ? "", instanceName ? "mysql${instanceSuffix}"
, port ? 3306
, containerName ? "mysql-database${instanceSuffix}"
, type
, properties ? {}
}:

let
  # By default, the socket file resides in $runtimeDir/mysqld/mysqld.sock.
  # We only change the path component: 'mysqld' into the instance name if no
  # instanceSuffix parameter is specified. Otherwise, we append the
  # instanceSuffix to 'mysqld'.
  #
  # This construction is used to allow the mysql client executable to work
  # without a socket parameter for the default configuration.

  mysqlSocket =
    if instanceName != "mysql" && instanceSuffix == "" then "${runtimeDir}/${instanceName}/mysqld.sock"
    else "${runtimeDir}/mysqld${instanceSuffix}/mysqld.sock";

  mysqlUsername = "root";

  pkg = mysqlConstructorFun {
    inherit port instanceName instanceSuffix;
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
} // properties

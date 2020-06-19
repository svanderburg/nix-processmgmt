{mysqlConstructorFun, dysnomia, runtimeDir}:
{port ? 3306, instanceSuffix ? "", type}:

let
  mysqlSocket = "${runtimeDir}/mysqld${instanceSuffix}/mysqld${instanceSuffix}.sock";

  mysqlUsername = "root";

  pkg = mysqlConstructorFun {
    inherit port instanceSuffix;
    postInstall = ''
      # Add Dysnomia container configuration file for MySQL database
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/mysql-database${instanceSuffix} <<EOF
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
  name = "mysql${instanceSuffix}";
  mysqlPort = port;

  inherit pkg type mysqlSocket mysqlUsername;

  providesContainer = "mysql-database${instanceSuffix}";
}

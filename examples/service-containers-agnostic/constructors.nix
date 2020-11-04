{ pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, tmpDir
, forceDisableUserChange
, processManager
, ids ? {}
}:

let
  constructors = import ../services-agnostic/constructors.nix {
    inherit pkgs stateDir logDir runtimeDir cacheDir tmpDir forceDisableUserChange processManager ids;
  };
in
{
  simpleWebappApache = import ./simple-webapp-apache.nix {
    apacheConstructorFun = constructors.simpleWebappApache;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableApacheWebApplication = true;
    });
    inherit forceDisableUserChange;
  };

  simpleAppservingTomcat = import ./simple-appserving-tomcat.nix {
    inherit stateDir;
    tomcatConstructorFun = constructors.simpleAppservingTomcat;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableTomcatWebApplication = true;
    });
  };

  mysql = import ./mysql.nix {
    inherit runtimeDir;
    mysqlConstructorFun = constructors.mysql;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableMySQLDatabase = true;
    });
  };

  postgresql = import ./postgresql.nix {
    inherit runtimeDir;
    postgresqlConstructorFun = constructors.postgresql;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enablePostgreSQLDatabase = true;
    });
  };

  simpleMongodb = import ./simplemongodb.nix {
    inherit (pkgs) stdenv;
    mongodbConstructorFun = constructors.simpleMongodb;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableMongoDatabase = true;
    });
  };

  extendableSupervisord = import ./extendable-supervisord.nix {
    inherit stateDir;
    inherit (pkgs) stdenv;
    supervisordConstructorFun = constructors.extendableSupervisord;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableSupervisordProgram = true;
    });
  };

  svnserve = import ./svnserve.nix {
    svnserveConstructorFun = constructors.svnserve;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableSubversionRepository = true;
    });
  };

  simpleInfluxdb = import ./simpleinfluxdb.nix {
    influxdbConstructorFun = constructors.simpleInfluxdb;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableInfluxDatabase = true;
    });
  };
}

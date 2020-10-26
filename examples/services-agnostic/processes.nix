{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir forceDisableUserChange processManager ids;
  };
in
rec {
  apache = rec {
    port = ids.httpPorts.apache or 0;

    pkg = constructors.simpleWebappApache {
      inherit port;
      serverAdmin = "root@localhost";
    };

    requiresUniqueIdsFor = [ "httpPorts" "uids" "gids" ];
  };

  mysql = rec {
    port = ids.mysqlPorts.mysql or 0;

    pkg = constructors.mysql {
      inherit port;
    };

    requiresUniqueIdsFor = [ "mysqlPorts" "uids" "gids" ];
  };

  postgresql = rec {
    port = ids.postgresqlPorts.postgresql or 0;

    pkg = constructors.postgresql {
      inherit port;
    };

    requiresUniqueIdsFor = [ "postgresqlPorts" "uids" "gids" ];
  };

  tomcat = rec {
    httpPort = ids.httpPorts.tomcat or 0;
    httpsPort = ids.httpsPorts.tomcat or 0;
    serverPort = ids.tomcatServerPorts.tomcat or 0;
    ajpPort = ids.tomcatAJPPorts.tomcat or 0;

    pkg = constructors.simpleAppservingTomcat {
      inherit httpPort httpsPort serverPort ajpPort;
    };

    requiresUniqueIdsFor = [ "httpPorts" "httpsPorts" "tomcatServerPorts" "tomcatAJPPorts" "uids" "gids" ];
  };

  mongodb = rec {
    port = ids.mongodbPorts.mongodb or 0;

    pkg = constructors.simpleMongodb {
      inherit port;
    };

    requiresUniqueIdsFor = [ "mongodbPorts" "uids" "gids" ];
  };

  supervisord = rec {
    inetHTTPServerPort = ids.inetHTTPPorts.supervisord or 0;

    pkg = constructors.extendableSupervisord {
      inherit inetHTTPServerPort;
    };

    requiresUniqueIdsFor = [ "inetHTTPPorts" ];
  };

  svnserve = rec {
    port = ids.svnPorts.svnserve or 0;

    pkg = constructors.svnserve {
      inherit port;
      svnBaseDir = "/repos";
      svnGroup = "root";
    };

    requiresUniqueIdsFor = [ "svnPorts" ];
  };

  influxdb = rec {
    httpPort = ids.influxdbPorts.influxdb or 0;
    rpcPort = httpPort + 2;

    pkg = constructors.simpleInfluxdb {
      inherit httpPort rpcPort;
    };

    requiresUniqueIdsFor = [ "influxdbPorts" "uids" "gids" ];
  };

  sshd = rec {
    port = ids.sshPorts.sshd or 0;

    pkg = constructors.sshd {
      inherit port;
    };

    requiresUniqueIdsFor = [ "sshPorts" "uids" "gids" ];
  };

  docker = {
    pkg = constructors.docker;
  };
}

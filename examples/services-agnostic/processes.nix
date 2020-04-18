{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? "sysvinit"
}:

let
  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir forceDisableUserChange processManager;
  };
in
rec {
  simpleWebappApache = rec {
    port = 8080;

    pkg = constructors.simpleWebappApache {
      inherit port;
      serverAdmin = "root@localhost";
    };
  };

  mysql = rec {
    port = 3307;

    pkg = constructors.mysql {
      inherit port;
    };
  };

  postgresql = rec {
    port = 6432;

    pkg = constructors.postgresql {
      inherit port;
    };
  };

  simple-appserving-tomcat = rec {
    httpPort = 8081;

    pkg = constructors.simpleAppservingTomcat {
      inherit httpPort;
    };
  };

  /*simpleMongodb = rec {
    pkg = constructors.simpleMongodb {};
  };*/

  extendableSupervisord = rec {
    pkg = constructors.extendableSupervisord {};
  };
}

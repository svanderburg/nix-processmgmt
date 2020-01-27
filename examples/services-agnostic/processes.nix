{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? "sysvinit"
}:

let
  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
  };
in
rec {
  static-webapp-apache = rec {
    port = 8080;

    pkg = constructors.static-webapp-apache {
      inherit port;
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

    pkg = constructors.simple-appserving-tomcat {
      inherit httpPort;
    };
  };
}

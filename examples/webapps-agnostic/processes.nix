{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
, webappMode ? null
}:

let
  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager webappMode;
  };
in
rec {
  webapp = rec {
    port = 5000;
    dnsName = "webapp.local";

    pkg = constructors.webapp {
      inherit port;
    };
  };

  nginxReverseProxy = rec {
    port = 8080;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp ];
      inherit port;
    } {};
  };
}

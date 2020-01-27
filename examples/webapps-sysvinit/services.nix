{ pkgs, distribution, invDistribution, system
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? true
}:

let
  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange;
  };
in
rec {
  webapp = rec {
    name = "webapp";
    port = 5000;
    dnsName = "webapp.local";
    pkg = constructors.webapp {
      inherit port;
    };
    type = "sysvinit-script";
  };

  nginxReverseProxy = rec {
    name = "nginxReverseProxy";
    port = 8080;
    pkg = constructors.nginxReverseProxy {
      inherit port;
    };
    dependsOn = {
      inherit webapp;
    };
    type = "sysvinit-script";
  };
}

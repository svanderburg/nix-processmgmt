{ pkgs, distribution, invDistribution, system
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? null # "sysvinit"
}:

let
  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
    webappMode = null;
  };

  processType =
    if processManager == null then "managed-process"
    else if processManager == "sysvinit" then "sysvinit-script"
    else if processManager == "systemd" then "systemd-unit"
    else if processManager == "supervisord" then "supervisord-program"
    else throw "Unknown process manager: ${processManager}";
in
rec {
  webapp = rec {
    name = "webapp";
    port = 5000;
    dnsName = "webapp.local";
    pkg = constructors.webapp {
      inherit port;
    };
    type = processType;
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
    type = processType;
  };
}

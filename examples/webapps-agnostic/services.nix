{ pkgs, distribution, invDistribution, system
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? null # "sysvinit"
}:

let
  sharedConstructors = import ../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange processManager;
  };

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
    webappMode = null;
  };

  processType =
    if processManager == null then "managed-process"
    else if processManager == "sysvinit" then "sysvinit-script"
    else if processManager == "systemd" then "systemd-unit"
    else if processManager == "supervisord" then "supervisord-program"
    else if processManager == "bsdrc" then "bsdrc-script"
    else if processManager == "cygrunsrv" then "cygrunsrv-service"
    else if processManager == "launchd" then "launchd-daemon"
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
    pkg = sharedConstructors.nginxReverseProxyHostBased {
      inherit port;
    };
    dependsOn = {
      inherit webapp;
    };
    type = processType;
  };
}

{ pkgs, distribution, invDistribution, system
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? "sysvinit"
}:

let
  sharedConstructors = import ../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange processManager;
  };

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
    webappMode = null;
  };

  processType = ../../nixproc/derive-dysnomia-process-type.nix {
    inherit processManager;
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

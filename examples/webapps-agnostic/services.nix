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
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  sharedConstructors = import ../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange processManager ids;
  };

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager ids;
    webappMode = null;
  };

  processType = import ../../nixproc/derive-dysnomia-process-type.nix {
    inherit processManager;
  };
in
rec {
  webapp = rec {
    name = "webapp";
    port = ids.webappPorts.webapp or 0;
    dnsName = "webapp.local";
    pkg = constructors.webapp {
      inherit port;
    };
    type = processType;

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  nginx = rec {
    name = "nginx";
    port = ids.nginxPorts.nginx or 0;
    pkg = sharedConstructors.nginxReverseProxyHostBased {
      inherit port;
    };
    dependsOn = {
      inherit webapp;
    };
    type = processType;

    requiresUniqueIdsFor = [ "nginxPorts" "uids" "gids" ];
  };
}

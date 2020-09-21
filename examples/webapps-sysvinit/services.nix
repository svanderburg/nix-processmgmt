{ pkgs, distribution, invDistribution, system
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? true
}:

let
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange;
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
    type = "sysvinit-script";

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  nginxReverseProxy = rec {
    name = "nginxReverseProxy";
    port = ids.nginxPorts.nginx or 0;
    pkg = constructors.nginxReverseProxy {
      inherit port;
    };
    dependsOn = {
      inherit webapp;
    };
    type = "sysvinit-script";

    requiresUniqueIdsFor = [ "nginxPorts" "uids" "gids" ];
  };
}

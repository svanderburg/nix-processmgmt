{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
, webappMode ? null
}:

let
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  sharedConstructors = import ../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange processManager ids;
  };

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager webappMode ids;
  };
in
rec {
  webapp = rec {
    port = ids.webappPorts.webapp or 0;
    dnsName = "webapp.local";

    pkg = constructors.webapp {
      inherit port;
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  nginx = rec {
    port = ids.nginxPorts.nginx or 0;

    pkg = sharedConstructors.nginxReverseProxyHostBased {
      webapps = [ webapp ];
      inherit port;
    } {};

    requiresUniqueIdsFor = [ "nginxPorts" "uids" "gids" ];
  };
}

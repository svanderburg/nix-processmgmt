{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange ids;
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

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp ];
      inherit port;
    } {};

    requiresUniqueIdsFor = [ "nginxPorts" "uids" "gids" ];
  };
}

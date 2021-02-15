{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};

  constructors = import ./constructors/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir forceDisableUserChange processManager ids;
  };
in
rec {
  supervisord = rec {
    inetHTTPServerPort = ids.inetHTTPPorts.supervisord or 0;

    pkg = constructors.extendableSupervisord {
      inherit inetHTTPServerPort;
    };

    requiresUniqueIdsFor = [ "inetHTTPPorts" ];
  };

  docker = {
    pkg = constructors.docker;
  };
}

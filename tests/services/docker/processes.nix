{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  constructors = import ../../../examples/services-agnostic/constructors/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir forceDisableUserChange processManager;
  };
in
rec {
  docker = {
    pkg = constructors.docker {};
  };

  docker-secondary = rec {
    pkg = constructors.docker {
      instanceSuffix = "-secondary";
      extraArgs = [ "--iptables=false" ]; # Avoids conflicting NAT settings with the primary instances
    };
  };
}

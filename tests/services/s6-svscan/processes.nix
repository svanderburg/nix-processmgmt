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
  s6-svscan-primary = rec {
    instanceSuffix = "-primary";
    pkg = constructors.s6-svscan {
      inherit instanceSuffix;
    };
  };

  s6-svscan-secondary = rec {
    instanceSuffix = "-secondary";
    pkg = constructors.s6-svscan {
      inherit instanceSuffix;
    };
  };
}

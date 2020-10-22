{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
, compoundProcessManager ? "supervisord"
}:

let
  createCompoundProcess = import ../../nixproc/create-compound-process/create-compound-process.nix {
    inherit pkgs system stateDir logDir runtimeDir tmpDir forceDisableUserChange processManager;
  };
in
{
  webappsSystem = {
    pkg = import ./webapps-system.nix {
      inherit createCompoundProcess stateDir forceDisableUserChange compoundProcessManager;
    };
  };
}

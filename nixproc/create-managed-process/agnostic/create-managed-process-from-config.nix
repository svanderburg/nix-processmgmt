{ configFile
, processManager
, createManagedProcessExpr
, system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  createManagedProcessFromConfig = configFile:
    let
      createManagedProcess = import createManagedProcessExpr {
        inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
      };

      properties = builtins.fromJSON (builtins.readFile configFile);

      normalizedProperties = properties // pkgs.lib.optionalAttrs (properties ? dependencies) {
        dependencies = map (dependency: createManagedProcessFromConfig "${dependency}/${builtins.substring 33 (builtins.stringLength dependency) (baseNameOf dependency)}.json") properties.dependencies;
      };
    in
    createManagedProcess normalizedProperties;
in
createManagedProcessFromConfig configFile

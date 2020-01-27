{ configFile
, processManager
, system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  createManagedProcessFromConfig = configFile:
    let
      createManagedProcess = import ./create-managed-process-universal.nix {
        inherit pkgs runtimeDir tmpDir forceDisableUserChange processManager;
      };

      properties = builtins.fromJSON (builtins.readFile configFile);

      normalizedProperties = properties // pkgs.stdenv.lib.optionalAttrs (properties ? dependencies) {
        dependencies = map (dependency: createManagedProcessFromConfig "${dependency}/${builtins.substring 33 (builtins.stringLength dependency) (baseNameOf dependency)}.json") properties.dependencies;
      };
    in
    createManagedProcess normalizedProperties;
in
createManagedProcessFromConfig configFile

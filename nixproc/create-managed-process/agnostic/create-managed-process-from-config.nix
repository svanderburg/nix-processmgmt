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

      configFileString = builtins.readFile configFile;

      properties = builtins.fromJSON (builtins.unsafeDiscardStringContext configFileString);

      # This attribute is a hack. It readds the dependencies of the JSON file as context to a frequently used string property so that the generated configuration artifact retains the runtime dependencies of the original JSON file.
      # This hack is needed because builtins.fromJSON can't work with strings that have context.

      propertiesWithContext = properties // pkgs.lib.optionalAttrs (properties ? process) {
        process = pkgs.lib.addContextFrom configFileString properties.process;
      } // pkgs.lib.optionalAttrs (properties ? foregroundProcess) {
        foregroundProcess = pkgs.lib.addContextFrom configFileString properties.foregroundProcess;
      } // pkgs.lib.optionalAttrs (properties ? daemon) {
        daemon = pkgs.lib.addContextFrom configFileString properties.daemon;
      };

      normalizedProperties = propertiesWithContext // pkgs.lib.optionalAttrs (properties ? dependencies) {
        dependencies = map (dependency: createManagedProcessFromConfig "${dependency}/${builtins.substring 33 (builtins.stringLength dependency) (baseNameOf dependency)}.json") properties.dependencies;
      };
    in
    createManagedProcess normalizedProperties;
in
createManagedProcessFromConfig configFile

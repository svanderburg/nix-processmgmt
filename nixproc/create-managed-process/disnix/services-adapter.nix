let
  # TODO: extraParams

  system = builtins.currentSystem;

  pkgs = import <nixpkgs> { inherit system; };

  processesFun = import (builtins.getEnv "PROCESSES_EXPR");

  processesFormalArgs = builtins.functionArgs processesFun;

  args = pkgs.lib.optionalAttrs (builtins.getEnv "NIXPROC_STATE_DIR" != "") {
    stateDir = builtins.getEnv "NIXPROC_STATE_DIR";
  } // pkgs.lib.optionalAttrs (builtins.getEnv "NIXPROC_RUNTIME_DIR" != "") {
    runtimeDir = builtins.getEnv "NIXPROC_RUNTIME_DIR";
  } // pkgs.lib.optionalAttrs (builtins.getEnv "NIXPROC_LOG_DIR" != "") {
    logDir = builtins.getEnv "NIXPROC_LOG_DIR";
  } // pkgs.lib.optionalAttrs (builtins.getEnv "NIXPROC_TMP_DIR" != "") {
    tmpDir = builtins.getEnv "NIXPROC_TMP_DIR";
  } // pkgs.lib.optionalAttrs (builtins.getEnv "NIXPROC_FORCE_DISABLE_USER_CHANGE" != "") {
    forceDisableUserChange = true;
  };

  processesArgs = builtins.intersectAttrs processesFormalArgs (args // {
    processManager = "disnix";
    inherit pkgs system;
  });
in
{distribution, invDistribution, pkgs, system}:

let
  processes = processesFun processesArgs;
in
pkgs.lib.mapAttrs (name: config:
  config // {
    inherit name;
    type = "process";
  }
) processes

{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, clientInterface ? (if builtins.getEnv "DISNIX_CLIENT_INTERFACE" == "" then "disnix-run-activity" else builtins.getEnv "DISNIX_CLIENT_INTERFACE")
, disnixPath ? (if builtins.getEnv "DISNIX_PATH" == "" then throw "Set DISNIX_PATH to the data directory of Disnix" else builtins.getEnv "DISNIX_PATH")
, exprFile
}@args:

let
  processesFun = import exprFile;

  processesFormalArgs = builtins.functionArgs processesFun;

  processesArgs = builtins.intersectAttrs processesFormalArgs (args // {
    processManager = "disnix";
  });

  processes = processesFun processesArgs;

  localhostTarget = {
    properties.hostname = "localhost";
    inherit system;
  };

  services = pkgs.lib.mapAttrs (processName: process: {
    name = processName;
    inherit (process) pkg;

    activatesAfter = builtins.listToAttrs (map (dependency: {
      inherit (dependency) name;
      value = builtins.getAttr dependency.name services;
    }) process.pkg.dependencies);

    type = "process";
    targets = [ localhostTarget ];
  }) processes;

  architectureFun = {system, pkgs}:
    {
      infrastructure.localhost = localhostTarget;
      inherit services;
    };

  manifest = import "${disnixPath}/manifest.nix";
in
manifest.generateManifestFromArchitectureFun {
  inherit pkgs clientInterface architectureFun;
  targetProperty = "hostname";
  deployState = false;
}

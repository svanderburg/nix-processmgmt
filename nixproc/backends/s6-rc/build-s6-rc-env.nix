{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, spoolDir ? "${stateDir}/spool"
, lockDir ? "${stateDir}/lock"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, extraParams ? {}
, exprFile ? null
, defaultBundleName ? "default"
}@args:

let
  processesFun = import exprFile;

  processesFormalArgs = builtins.functionArgs processesFun;

  processesArgs = builtins.intersectAttrs processesFormalArgs (args // {
    processManager = "s6-rc";
  } // extraParams);

  processes = if exprFile == null then {} else processesFun processesArgs;

  createServiceBundle = import ./create-service-bundle.nix {
    inherit (pkgs) stdenv lib;
  };

  processesList = map (processName:
    let
      process = builtins.getAttr processName processes;
    in
    process.pkg
  ) (builtins.attrNames processes);

  defaultBundle = createServiceBundle {
    name = defaultBundleName;
    contents = processesList;
  };
in
pkgs.buildEnv {
  name = "s6-rc";
  paths = [ defaultBundle ] ++ processesList;
}

{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${cacheDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, spoolDir ? "${stateDir}/spool"
, lockDir ? "${stateDir}/lock"
, libDir ? "${stateDir}/lib"
, forceDisableUserChange ? false
, callingUser ? null
, callingGroup ? null
, extraParams ? {}
, exprFile ? null
}@args:

let
  processesFun = import exprFile;

  processesFormalArgs = builtins.functionArgs processesFun;

  processesArgs = builtins.intersectAttrs processesFormalArgs (args // {
    processManager = "launchd";
  } // extraParams);

  processes = if exprFile == null then {} else processesFun processesArgs;
in
pkgs.buildEnv {
  name = "launchd";
  paths = map (processName:
    let
      process = builtins.getAttr processName processes;
    in
    process.pkg
  ) (builtins.attrNames processes);
}

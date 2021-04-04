{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${cacheDir}/cache"
, spoolDir ? "${stateDir}/spool"
, lockDir ? "${stateDir}/lock"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, callingUser ? null
, callingGroup ? null
, exprFile ? null
, extraParams ? {}
}@args:

let
  processesFun = import exprFile;

  processesFormalArgs = builtins.functionArgs processesFun;

  processesArgs = builtins.intersectAttrs processesFormalArgs (args // {
    processManager = "bsdrc";
  } // extraParams);

  processes = if exprFile == null then {} else processesFun processesArgs;
in
pkgs.buildEnv {
  name = "rc.d";
  paths = map (processName:
    let
      process = builtins.getAttr processName processes;
    in
    process.pkg
  ) (builtins.attrNames processes);
}

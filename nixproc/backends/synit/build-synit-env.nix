{ pkgs ? import <nixpkgs> { inherit system; }, system ? builtins.currentSystem
, stateDir ? "/var", runtimeDir ? "${stateDir}/run", logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache", spoolDir ? "${stateDir}/spool"
, lockDir ? "${stateDir}/lock", libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false, callingUser ? null, callingGroup ? null
, extraParams ? { }, exprFile ? null }@args:

let
  processesFun = import exprFile;

  processesFormalArgs = builtins.functionArgs processesFun;

  processesArgs = builtins.intersectAttrs processesFormalArgs
    (args // { processManager = "synit"; } // extraParams);

  processes = if exprFile == null then { } else processesFun processesArgs;
in pkgs.buildEnv {
  name = "syndicate-services";
  paths = map ({ pkg, ... }: pkg) (builtins.attrValues processes);
}

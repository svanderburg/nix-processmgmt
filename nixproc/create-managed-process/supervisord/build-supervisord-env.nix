{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, extraParams ? {}
, exprFile ? null
}@args:

let
  processesFun = import exprFile;

  processesFormalArgs = builtins.functionArgs processesFun;

  processesArgs = builtins.intersectAttrs processesFormalArgs (args // {
    processManager = "supervisord";
  } // extraParams);

  processes = if exprFile == null then {} else processesFun processesArgs;
in
pkgs.buildEnv {
  name = "supervisord.d";
  paths = map (processName:
    let
      process = builtins.getAttr processName processes;
    in
    process.pkg
  ) (builtins.attrNames processes);
  postBuild = ''
    cp ${./supervisord.conf} $out/supervisord.conf
  '';
}

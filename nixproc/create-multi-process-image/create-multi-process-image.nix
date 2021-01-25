{dockerTools, stdenv, pkgs, system, generators}:

{ interactive ? true
, exprFile
, extraParams ? {}
, contents ? []
, runAsRoot ? ""
, config ? {}
, processManager
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, forceDisableUserChange ? false
, ...
}@args:

let
  # Determine which parameters can be propagated to buildImage and which are customizations
  buildImageFormalArgs = builtins.functionArgs dockerTools.buildImage;
  buildImageArgs = removeAttrs (builtins.intersectAttrs buildImageFormalArgs args) [ "contents" "runAsRoot" "config" ];

  commonTools = (import ../../tools { inherit pkgs; }).common;

  generateImageArgsModule = if builtins.hasAttr processManager generators
    then builtins.getAttr processManager generators
    else throw "Cannot use process manager: ${processManager} in a multi-process container!";

  processManagerArgs = import generateImageArgsModule {
    inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams pkgs system;
  };

  setupProcessManagement = import ../backends/docker/setup.nix {
    inherit (pkgs) dockerTools stdenv dysnomia findutils glibc;
    inherit (processManagerArgs) credentialsSpec;
    inherit commonTools stateDir runtimeDir forceDisableUserChange;
  };
in
dockerTools.buildImage ({
  contents = stdenv.lib.optionals interactive [ pkgs.glibc.bin pkgs.bashInteractive pkgs.coreutils pkgs.gnugrep pkgs.findutils pkgs.procps pkgs.utillinux pkgs.less ]
    ++ processManagerArgs.contents
    ++ contents;

  runAsRoot =
    setupProcessManagement
    + processManagerArgs.runAsRoot
    + stdenv.lib.optionalString interactive import ./configure-bashrc.nix
    +
    ''

      ${runAsRoot}
    '';

  config = stdenv.lib.recursiveUpdate {
    Cmd = processManagerArgs.cmd;
  } config;
} // buildImageArgs)

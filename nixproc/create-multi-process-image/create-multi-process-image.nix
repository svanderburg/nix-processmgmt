{dockerTools, stdenv, pkgs, system}:

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

  processManagerArgs =
    if processManager == "sysvinit" then import ./generate-sysvinit-args.nix {
      inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams pkgs system;
    }
    else if processManager == "supervisord" then import ./generate-supervisord-args.nix {
      inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams pkgs system;
    }
    else if processManager == "disnix" then import ./generate-disnix-args.nix {
      inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams pkgs system;
    }
    else throw "Unsupported process manager: ${processManager}";

  setupProcessManagement = import ../create-managed-process/docker/setup.nix {
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

{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, processManager ? "supervisord"
, forceDisableUserChange ? false
}:

let
  createMultiProcessImage = import ../../nixproc/create-multi-process-image/create-multi-process-image.nix {
    inherit pkgs system;
    inherit (pkgs) dockerTools stdenv;
  };
in
createMultiProcessImage {
  name = "multiprocess";
  tag = "test";
  exprFile = ../webapps-agnostic/processes.nix;
  inherit processManager forceDisableUserChange;
}

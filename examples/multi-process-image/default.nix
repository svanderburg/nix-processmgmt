{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, processManager ? "supervisord"
, forceDisableUserChange ? false
}:

let
  createMultiProcessImage = import ../../nixproc/create-image-from-steps/create-multi-process-image-universal.nix {
    inherit pkgs;
  };
in
createMultiProcessImage {
  name = "multiprocess";
  tag = "test";
  exprFile = ../webapps-agnostic/processes.nix;
  inherit processManager forceDisableUserChange;
}

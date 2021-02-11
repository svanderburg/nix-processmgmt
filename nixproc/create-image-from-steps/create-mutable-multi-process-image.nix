{pkgs}:
{processManager, steps, ...}@input:

let
  _input = rec {
    stateDir = "/var";
    runtimeDir = "${stateDir}/run";
  } // input;

  processManagerSpecificStepsFile = builtins.getAttr processManager steps;
in
import ./create-image-from-steps.nix {
  inherit pkgs;
  common = {
    system = builtins.currentSystem;
  };
  input = _input;

  steps = [
    ./steps/init.nix
    ./steps/basic.nix
    ./steps/interactive.nix
    ./steps/man.nix
    ./steps/nix-processmgmt-dynamic.nix
  ]
  ++ import processManagerSpecificStepsFile
  ++ [
    ./steps/bootstrap-init.nix
    ./steps/nix-support.nix
  ];
}

{pkgs}:
{processManager, steps, ...}@input:

let
  _input = rec {
    stateDir = "/var";
    runtimeDir = "${stateDir}/run";
    forceDisableUserChange = false;
    extraParams = {};
  } // input;

  processManagerSpecificStepsFile = builtins.getAttr processManager steps;
in
import ./create-image-from-steps.nix {
  inherit pkgs;
  input = _input;

  common = {
    system = builtins.currentSystem;
  };

  steps = [
    ./steps/init.nix
    ./steps/basic.nix
    ./steps/interactive.nix
    ./steps/man.nix
    ./steps/nix-processmgmt-static.nix
  ]
  ++ import processManagerSpecificStepsFile;
}

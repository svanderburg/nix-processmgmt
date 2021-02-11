{pkgs, steps, common ? {}, input}:

let
  generatedConfig = import ./generate-config-from-steps.nix {
    inherit pkgs common input steps;
  };
in
pkgs.dockerTools.buildImage generatedConfig

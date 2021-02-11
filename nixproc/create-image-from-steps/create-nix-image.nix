{pkgs}:
input:

import ./create-image-from-steps.nix {
  inherit pkgs input;

  common = {
    system = builtins.currentSystem;
  };

  steps = [
    ./steps/init.nix
    ./steps/basic.nix
    ./steps/interactive.nix
    ./steps/man.nix
    ./steps/nix-support.nix
  ];
}

{dockerTools, stdenv, pkgs, system}:

import ./create-multi-process-image.nix {
  inherit dockerTools stdenv pkgs system;
  generators = {
    disnix = ../backends/disnix/generate-disnix-image-args.nix;
    s6-rc = ../backends/s6-rc/generate-s6-rc-image-args.nix;
    supervisord = ../backends/supervisord/generate-supervisord-image-args.nix;
    sysvinit = ../backends/sysvinit/generate-sysvinit-image-args.nix;
  };
}

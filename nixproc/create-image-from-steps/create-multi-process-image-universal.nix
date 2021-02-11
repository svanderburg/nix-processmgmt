{pkgs}:
input:

import ./create-multi-process-image.nix {
  inherit pkgs;
} (input // {
  steps = {
    disnix = ../backends/disnix/image-steps/static-steps.nix;
    s6-rc = ../backends/s6-rc/image-steps/static-steps.nix;
    supervisord = ../backends/supervisord/image-steps/static-steps.nix;
    sysvinit = ../backends/sysvinit/image-steps/static-steps.nix;
  };
})

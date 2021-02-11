{pkgs}:
input:

import ./create-mutable-multi-process-image.nix {
  inherit pkgs;
} (input // {
  steps = {
    disnix = ../backends/disnix/image-steps/dynamic-steps.nix;
    s6-rc = ../backends/s6-rc/image-steps/dynamic-steps.nix;
    supervisord = ../backends/supervisord/image-steps/dynamic-steps.nix;
    sysvinit = ../backends/sysvinit/image-steps/dynamic-steps.nix;
  };
})

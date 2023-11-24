{ nixpkgs ? <nixpkgs>
, system ? builtins.currentSystem
}:

import ./agnostic.nix {
  inherit nixpkgs system;

  processManagerModules = {
    disnix = ../backends/disnix/test-module;
    docker = ../backends/docker/test-module;
    s6-rc = ../backends/s6-rc/test-module;
    supervisord = ../backends/supervisord/test-module;
    synit = ../backends/synit/test-module;
    systemd = ../backends/systemd/test-module;
    sysvinit = ../backends/sysvinit/test-module;
  };

  profileSettingModules = {
    privileged = ./profiles/privileged.nix;
    unprivileged = ./profiles/unprivileged.nix;
  };
}

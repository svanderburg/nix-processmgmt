{profileSettings, exprFile, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvProcessManager = import ../../sysvinit/build-sysvinit-env.nix ({
    inherit pkgs system;
    exprFile = ../../../../tests/processes-s6-svscan.nix;
  } // profileSettings.params);

  processesEnvSystem = import ../build-s6-rc-env.nix ({
    inherit pkgs system exprFile;
  } // profileSettings.params);
in
{
  nixosModules = [];

  systemPackages = [
    tools.sysvinit
    tools.s6-rc
    pkgs.s6-rc
  ];

  pathsInNixDB = [ processesEnvProcessManager processesEnvSystem ];

  # TODO: how to determine service readiness of s6?
  deployProcessManager = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "sysvinit"; processesEnv = processesEnvProcessManager; }}"
    )
    machine.succeed("sleep 3")
  '';

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "s6-rc"; processesEnv = processesEnvSystem; }}"
    )
  '';
}

{profileSettings, exprFile, extraParams, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvProcessManager = import ../../sysvinit/build-sysvinit-env.nix ({
    inherit pkgs system;
    exprFile = ./processes-s6-svscan.nix;
  } // profileSettings.params);

  processesEnvSystem = import ../build-s6-rc-env.nix ({
    inherit pkgs system exprFile extraParams;
  } // profileSettings.params);
in
{
  inherit (profileSettings) params;

  nixosModules = [];

  systemPackages = [
    tools.sysvinit
    tools.s6-rc
    pkgs.s6-rc
  ];

  additionalPaths = [ processesEnvProcessManager processesEnvSystem ];

  deployProcessManager = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "sysvinit"; processesEnv = processesEnvProcessManager; }}"
    )
    machine.wait_for_file("${profileSettings.params.runtimeDir}/service/.s6-svscan")
  '';

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "s6-rc"; processesEnv = processesEnvSystem; }}"
    )
  '';
}

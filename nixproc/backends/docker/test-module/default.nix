{profileSettings, exprFile, extraParams, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvProcessManager = import ../../sysvinit/build-sysvinit-env.nix ({
    inherit pkgs system;
    exprFile = ./processes-docker.nix;
  } // profileSettings.params);

  processesEnvSystem = import ../build-docker-env.nix ({
    inherit pkgs system exprFile extraParams;
  }
  // profileSettings.params);
in
{
  nixosModules = [];

  systemPackages = [
    tools.sysvinit
    tools.docker
    pkgs.docker
  ];

  pathsInNixDB = [ processesEnvProcessManager processesEnvSystem ];

  deployProcessManager = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "sysvinit"; processesEnv = processesEnvProcessManager; }}"
    )
    machine.wait_for_file("${profileSettings.params.stateDir}/run/docker.sock")
  '';

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "docker"; processesEnv = processesEnvSystem; }}"
    )
  '';
}

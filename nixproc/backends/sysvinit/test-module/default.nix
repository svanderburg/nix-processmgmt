{profileSettings, exprFile, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvSystem = import ../build-sysvinit-env.nix ({
    inherit pkgs system exprFile;
  } // profileSettings.params);
in
{
  nixosModules = [];

  systemPackages = [
    tools.sysvinit
  ];

  pathsInNixDB = [ processesEnvSystem ];

  deployProcessManager = "";

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "sysvinit"; processesEnv = processesEnvSystem; }}"
    )
  '';
}

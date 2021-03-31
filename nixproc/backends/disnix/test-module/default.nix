{profileSettings, exprFile, extraParams, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvSystem = import ../build-disnix-env.nix ({
    inherit pkgs system exprFile extraParams;
    disnixDataDir = "${pkgs.disnix}/share/disnix";
  } // profileSettings.params);
in
{
  nixosModules = [];

  systemPackages = [
    tools.disnix
    pkgs.disnix
  ];

  pathsInNixDB = [ processesEnvSystem ];

  deployProcessManager = "";

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "disnix"; processesEnv = processesEnvSystem; }}"
    )
  '';
}

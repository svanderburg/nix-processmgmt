{profileSettings, exprFile, extraParams, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvSystem = import ../build-sysvinit-env.nix ({
    inherit pkgs system exprFile extraParams;
  } // profileSettings.params);
in
{
  inherit (profileSettings) params;

  nixosModules = [];

  systemPackages = [
    tools.sysvinit
  ];

  additionalPaths = [ processesEnvSystem ];

  deployProcessManager = "";

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "sysvinit"; processesEnv = processesEnvSystem; }}"
    )
  '';
}

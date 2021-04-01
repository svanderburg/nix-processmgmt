{profileSettings, exprFile, extraParams, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvProcessManager = import ../../sysvinit/build-sysvinit-env.nix ({
    inherit pkgs system;
    exprFile = ./processes-supervisord.nix;
  } // profileSettings.params);

  processesEnvSystem = import ../build-supervisord-env.nix ({
    inherit pkgs system exprFile extraParams;
  } // profileSettings.params);
in
{
  nixosModules = [];

  systemPackages = [
    tools.sysvinit
    tools.supervisord
    pkgs.pythonPackages.supervisor
  ];

  pathsInNixDB = [ processesEnvProcessManager processesEnvSystem ];

  deployProcessManager = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "sysvinit"; processesEnv = processesEnvProcessManager; }}"
    )
    machine.wait_for_open_port(9001)
  '';

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "supervisord"; envVars = [ "SUPERVISORD_CONF_DIR=${profileSettings.params.stateDir}/lib/supervisord" ]; processesEnv = processesEnvSystem; }}"
    )
  '';
}

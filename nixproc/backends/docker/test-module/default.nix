{profileSettings, exprFile, extraParams, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  # We cannot deploy Docker as unprivileged user. Use a privileged installation instead
  profileSettingsProcessManager = import ../../../test-driver/profiles/privileged.nix;

  # For privileged deployments, use a different directory than /var, because it does not have the right SELinux context to work with containers
  profileSettingsSystem = if profileSettings.params.stateDir == "/var" then profileSettings // {
    params = profileSettings.params // rec {
      stateDir = "/dockervar";
      runtimeDir = "${stateDir}/run";
    };
  } else profileSettings;

  processesEnvProcessManager = import ../../sysvinit/build-sysvinit-env.nix ({
    inherit pkgs system;
    exprFile = ./processes-docker.nix;
  } // profileSettingsProcessManager.params);

  processesEnvSystem = import ../build-docker-env.nix ({
    inherit pkgs system exprFile extraParams;
  } // profileSettingsSystem.params);
in
{
  inherit (profileSettingsSystem) params;

  nixosModules = [];

  systemPackages = [
    tools.sysvinit
    tools.docker
    pkgs.docker
  ];

  pathsInNixDB = [ processesEnvProcessManager processesEnvSystem ];

  deployProcessManager = ''
    machine.succeed(
        "${executeDeploy { profileSettings = profileSettingsProcessManager; processManager = "sysvinit"; processesEnv = processesEnvProcessManager; }}"
    )
    machine.wait_for_file("${profileSettingsProcessManager.params.stateDir}/run/docker.sock")
  '' + pkgs.lib.optionalString profileSettings.params.forceDisableUserChange ''
    machine.succeed("usermod -a -G docker unprivileged")
  '';

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { profileSettings = profileSettingsSystem; processManager = "docker"; processesEnv = processesEnvSystem; }}"
    )
  '';
}

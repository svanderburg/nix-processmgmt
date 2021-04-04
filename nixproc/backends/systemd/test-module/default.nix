{profileSettings, exprFile, extraParams, tools, pkgs, system}:

let
  executeDeploy = import ../../../test-driver/util/execute-deploy.nix {
    inherit (pkgs) lib;
  };

  processesEnvSystem = import ../build-systemd-env.nix ({
    inherit pkgs system exprFile extraParams;
  } // profileSettings.params);

  deployEnv = if profileSettings.params.forceDisableUserChange
    then "XDG_RUNTIME_DIR=/run/user/1000"
    else "SYSTEMD_TARGET_DIR=/etc/systemd-mutable/system";
in
{
  inherit (profileSettings) params;

  nixosModules = pkgs.lib.optional profileSettings.params.forceDisableUserChange ./xserver-autologin-module.nix;

  systemPackages = [
    tools.systemd
  ];

  pathsInNixDB = [ processesEnvSystem ];

  deployProcessManager = ''
    machine.succeed("mkdir -p /etc/systemd-mutable/system")
  '' + pkgs.lib.optionalString profileSettings.params.forceDisableUserChange ''
    machine.wait_for_unit("display-manager.service")
    machine.wait_until_succeeds("pgrep -f 'systemd --user'")
  '';

  deploySystem = ''
    machine.succeed(
        "${executeDeploy { inherit profileSettings; processManager = "systemd"; envVars = [ deployEnv ]; extraDeployArgs = pkgs.lib.optionalString profileSettings.params.forceDisableUserChange [ "--user" ]; processesEnv = processesEnvSystem; }}"
    )
  '';
}

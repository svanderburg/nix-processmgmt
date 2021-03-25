{lib}:
{processManager, profileSettings, envVars ? [], extraDeployArgs ? [], processesEnv}:

let
  executeCommand = import ./execute-command.nix {
    inherit lib;
  };
in
executeCommand {
  inherit (profileSettings.params) forceDisableUserChange;
  command = "${toString envVars} nixproc-${processManager}-deploy ${toString profileSettings.deployArgs} ${toString extraDeployArgs} ${processesEnv}";
}

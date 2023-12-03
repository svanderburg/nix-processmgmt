{ profileSettings, exprFile, extraParams, tools, pkgs, system }:

let
  executeDeploy =
    import ../../../test-driver/util/execute-deploy.nix { inherit (pkgs) lib; };

  processesEnvSystem = import ../build-synit-env.nix
    ({ inherit pkgs system exprFile extraParams; } // profileSettings.params);
in {
  inherit (profileSettings) params;

  nixosModules = [ ./nixos-syndicate-server.nix ];

  systemPackages = [ tools.synit ];

  additionalPaths = [ processesEnvSystem ];

  deployProcessManager = "";

  deploySystem = ''
    machine.wait_for_unit("syndicate-server.service")
    machine.succeed("${
      executeDeploy {
        inherit profileSettings;
        processManager = "synit";
        processesEnv = processesEnvSystem;
      }
    }")
  '';
}

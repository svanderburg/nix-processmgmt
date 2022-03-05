{ nixpkgs ? <nixpkgs>
, system ? builtins.currentSystem
, processManagerModules ? {}
, profileSettingModules ? {}
}:

let
  pkgs = import nixpkgs { inherit system; };

  tools = import ../../tools {
    inherit pkgs system;
  };

  testSystemVariantForProcessManager = {processManager, profileSettings, exprFile, extraParams ? {}, nixosConfig ? null, systemPackages ? [], initialTests ? null, readiness ? null, tests ? null, postTests ? null}:
    let
      processManagerModule = builtins.getAttr processManager processManagerModules;

      processManagerSettings = import processManagerModule {
        inherit profileSettings exprFile extraParams pkgs system tools;
      };

      processesFun = import exprFile;
      processesFormalArgs = builtins.functionArgs processesFun;

      processesArgs = builtins.intersectAttrs processesFormalArgs ({
        inherit pkgs system processManager;
      } // processManagerSettings.params // extraParams);

      processes = processesFun processesArgs;
    in
    with import "${nixpkgs}/nixos/lib/testing-python.nix" { inherit system; };

    makeTest {
      machine =
        {pkgs, lib, ...}:

        {
          imports =
            profileSettings.nixosModules
            ++ processManagerSettings.nixosModules
            ++ lib.optional (nixosConfig != null) nixosConfig;

          virtualisation.additionalPaths = processManagerSettings.additionalPaths;

          nix.extraOptions = ''
            substitute = false
          '';

          environment.systemPackages = [
            pkgs.dysnomia
            tools.common
          ]
          ++ processManagerSettings.systemPackages
          ++ systemPackages;
        };

      testScript =
        ''
          start_all()
        ''
        + processManagerSettings.deployProcessManager
        + processManagerSettings.deploySystem
        + pkgs.lib.optionalString (initialTests != null) (initialTests (processManagerSettings.params // { inherit processes; }))

        # Execute readiness check for all process instances
        + pkgs.lib.optionalString (readiness != null)
            (pkgs.lib.concatMapStrings (instanceName:
              let
                instance = builtins.getAttr instanceName processes;
              in
              readiness ({ inherit instanceName instance; } // processManagerSettings.params)
            ) (builtins.attrNames processes))

        # Execute tests for all process instances
        + pkgs.lib.optionalString (tests != null)
            (pkgs.lib.concatMapStrings (instanceName:
              let
                instance = builtins.getAttr instanceName processes;
              in
              tests ({ inherit instanceName instance; } // processManagerSettings.params)
            ) (builtins.attrNames processes))

        + pkgs.lib.optionalString (postTests != null) (postTests (processManagerSettings.params // { inherit processes; }));
    };
in
{ processManagers
, profiles
, exprFile
, extraParams ? {}
, nixosConfig ? null
, systemPackages ? []
, initialTests ? null
, readiness ? null
, tests ? null
, postTests ? null
}:

pkgs.lib.genAttrs profiles (profile:
  let
    profileSettingsModule = builtins.getAttr profile profileSettingModules;
    profileSettings = import profileSettingsModule;
  in
  pkgs.lib.genAttrs processManagers (processManager:
    testSystemVariantForProcessManager {
      inherit processManager profileSettings exprFile extraParams nixosConfig systemPackages initialTests readiness tests postTests;
    }
  )
)

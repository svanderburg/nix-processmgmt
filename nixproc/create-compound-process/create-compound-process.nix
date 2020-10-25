{pkgs, system, stateDir, logDir, runtimeDir, tmpDir, forceDisableUserChange, processManager}:

let
  createManagedProcess = import ../../nixproc/create-managed-process/agnostic/create-managed-process-universal.nix {
    inherit pkgs runtimeDir stateDir logDir tmpDir forceDisableUserChange processManager;
  };

  compoundLogDir = logDir;
  compoundRuntimeDir = runtimeDir;
in

{ name, exprFile
, processManager
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, path ? []
, extraParams ? {}
, overrides ? {}
}:

let
  processArgs =
    if processManager == "sysvinit" then import ./generate-sysvinit-args.nix {
      inherit pkgs system exprFile stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange extraParams;
    }
    else if processManager == "disnix" then import ./generate-disnix-args.nix {
      inherit pkgs system exprFile stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange extraParams;
    }
    else if processManager == "bsdrc" then import ./generate-bsdrc-args.nix {
      inherit pkgs system exprFile stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange extraParams;
    }
    else if processManager == "supervisord" then import ./generate-supervisord-args.nix {
      inherit pkgs system name compoundLogDir compoundRuntimeDir exprFile stateDir runtimeDir cacheDir logDir tmpDir forceDisableUserChange extraParams;
    }

    # We can't embed launchd, cygrunsrv, because these supervisor processes cannot be managed by anything else
    # Managing docker containers does not make sense
    # In theory, systemd could work in containers, but workarounds need to be applied, e.g. cgroup permissions

    else throw "Unsupported process manager: ${processManager}";

  commonTools = (import ../../tools { inherit pkgs system; }).common;
in
createManagedProcess (pkgs.lib.recursiveUpdate {
  inherit name path overrides;
  initialize = ''
    ${commonTools}/bin/nixproc-init-state --state-dir "${stateDir}" --log-dir "${logDir}" --runtime-dir "${runtimeDir}" --cache-dir "${cacheDir}" --tmp-dir "${tmpDir}" ${pkgs.lib.optionalString forceDisableUserChange "--force-disable-user-change"}
  '';
} processArgs)
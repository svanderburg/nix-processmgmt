{ pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, libDir
, tmpDir
, forceDisableUserChange
, processManager
, ids ? {}
}:

let
  createManagedProcess = import ../../../nixproc/create-managed-process/universal/create-managed-process-universal.nix {
    inherit pkgs runtimeDir stateDir logDir tmpDir forceDisableUserChange processManager ids;
  };
in
{
  nginx = import ./nginx {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv nginx;
  };

  nginxReverseProxyHostBased = import ./nginx/nginx-reverse-proxy-hostbased.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv lib writeTextFile nginx;
  };

  supervisord = import ./supervisord {
    inherit createManagedProcess runtimeDir logDir;
    inherit (pkgs.python3Packages) supervisor;
  };

  extendableSupervisord = import ./supervisord/extendable.nix {
    inherit createManagedProcess libDir runtimeDir logDir;
    inherit (pkgs) writeTextFile;
    inherit (pkgs.python3Packages) supervisor;
  };

  docker = import ./docker {
    inherit createManagedProcess runtimeDir libDir;
    inherit (pkgs) docker kmod;
  };

  s6-svscan = import ./s6-svscan {
    inherit createManagedProcess runtimeDir;
    inherit (pkgs) s6 execline;
  };
}

{ pkgs
, stateDir
, logDir
, runtimeDir
, tmpDir
, forceDisableUserChange
, processManager
, webappMode # set to 'foreground' to make them all foreground process, 'daemon' to make them all daemons. null is to pick best option for the selected processManager
, ids ? {}
}:

let
  createManagedProcess = import ../../../nixproc/create-managed-process/universal/create-managed-process-universal.nix {
    inherit pkgs runtimeDir stateDir logDir tmpDir forceDisableUserChange processManager ids;
  };

  webappExpr = if webappMode == "foreground" then ./webapp/webapp-fg.nix
    else if webappMode == "daemon" then ./webapp/webapp-daemon.nix
    else ./webapp;
in
{
  webapp = import webappExpr {
    inherit createManagedProcess tmpDir;
  };
}

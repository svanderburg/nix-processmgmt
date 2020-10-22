{createCompoundProcess, compoundProcessManager, stateDir, forceDisableUserChange}:

createCompoundProcess {
  name = "webapps-system";
  stateDir = "${stateDir}/lib/webapps-system";
  exprFile = ../webapps-agnostic/processes.nix;
  inherit forceDisableUserChange;
  processManager = compoundProcessManager;
  overrides = {
    sysvinit.runlevels = [ 3 4 5 ];
  };
}

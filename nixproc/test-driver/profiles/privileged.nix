{
  params = rec {
    stateDir = "/var";
    runtimeDir = "${stateDir}/run";
    forceDisableUserChange = false;
  };

  deployArgs = "";

  nixosModules = [];
}

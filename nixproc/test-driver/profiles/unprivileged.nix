{
  params = rec {
    stateDir = "/home/unprivileged/var";
    runtimeDir = "${stateDir}/run";
    forceDisableUserChange = true;
    callingUser = "unprivileged";
    callingGroup = "users";
  };

  deployArgs = [ "--state-dir" "/home/unprivileged/var" "--force-disable-user-change" ];

  nixosModules = [ ./unprivileged-user-module.nix ];
}

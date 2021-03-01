{stdenv, lib, execline, createCredentials, logDir, logDirUser ? "s6-log", logDirGroup ? "s6-log", forceDisableUserChange}:

rec {
  createLogServiceForLongRunService = import ./create-log-service-for-longrun-service.nix {
    inherit stdenv lib execline logDir logDirUser logDirGroup forceDisableUserChange;
  };
  createLongRunService = import ./create-longrun-service.nix {
    inherit stdenv lib createCredentials createLogServiceForLongRunService;
  };
  createOneShotService = import ./create-oneshot-service.nix {
    inherit stdenv lib createCredentials;
  };
  createServiceBundle = import ./create-service-bundle.nix {
    inherit stdenv lib;
  };
}

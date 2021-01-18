{stdenv, createCredentials}:

{
  createLongRunService = import ./create-longrun-service.nix {
    inherit stdenv createCredentials;
  };
  createOneShotService = import ./create-oneshot-service.nix {
    inherit stdenv createCredentials;
  };
  createServiceBundle = import ./create-service-bundle.nix {
    inherit stdenv;
  };
}

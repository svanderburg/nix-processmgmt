{ pkgs
, stateDir
, cacheDir
, logDir
, runtimeDir
, tmpDir
, forceDisableUserChange
, ids ? {}
}:

let
  createSystemVInitScript = import ../../nixproc/create-managed-process/sysvinit/create-sysvinit-script.nix {
    inherit (pkgs) stdenv writeTextFile daemon;
    inherit runtimeDir logDir tmpDir forceDisableUserChange;

    createCredentials = import ../../nixproc/create-credentials {
      inherit (pkgs) stdenv;
      inherit ids;
    };

    initFunctions = import ../../nixproc/create-managed-process/sysvinit/init-functions.nix {
      basePackages = [ pkgs.coreutils pkgs.gnused pkgs.inetutils pkgs.gnugrep pkgs.sysvinit ];
      inherit (pkgs) stdenv fetchurl;
      inherit runtimeDir;
    };
  };
in
{
  webapp = import ./webapp.nix {
    inherit createSystemVInitScript tmpDir;
  };

  nginxReverseProxy = import ./nginx-reverse-proxy.nix {
    inherit createSystemVInitScript stateDir logDir cacheDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile nginx;
  };
}

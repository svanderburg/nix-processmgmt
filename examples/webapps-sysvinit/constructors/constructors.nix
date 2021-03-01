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
  createSystemVInitScript = import ../../../nixproc/backends/sysvinit/create-sysvinit-script.nix {
    inherit (pkgs) stdenv writeTextFile lib daemon;
    inherit runtimeDir logDir tmpDir forceDisableUserChange;

    createCredentials = import ../../../nixproc/create-credentials {
      inherit (pkgs) stdenv lib;
      inherit ids forceDisableUserChange;
    };

    initFunctions = import ../../../nixproc/backends/sysvinit/init-functions.nix {
      basePackages = [ pkgs.coreutils pkgs.gnused pkgs.inetutils pkgs.gnugrep pkgs.sysvinit ];
      inherit (pkgs) stdenv fetchurl;
      inherit runtimeDir;
    };
  };
in
{
  webapp = import ./webapp {
    inherit createSystemVInitScript tmpDir;
  };

  nginxReverseProxy = import ./nginx/nginx-reverse-proxy.nix {
    inherit createSystemVInitScript stateDir logDir cacheDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv lib writeTextFile nginx;
  };
}

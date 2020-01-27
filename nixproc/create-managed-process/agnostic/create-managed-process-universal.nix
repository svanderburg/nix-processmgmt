{pkgs, runtimeDir, tmpDir, forceDisableUserChange ? false, processManager ? null}:

let
  basePackages = [
    pkgs.coreutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.inetutils
  ];

  createCredentials = import ../../create-credentials {
    inherit (pkgs) stdenv;
  };

  createSystemVInitScript = import ../sysvinit/create-sysvinit-script.nix {
    inherit (pkgs) stdenv writeTextFile daemon;
    inherit createCredentials runtimeDir tmpDir forceDisableUserChange;

    initFunctions = import ../sysvinit/init-functions.nix {
      inherit (pkgs) stdenv fetchurl;
      inherit runtimeDir;
      basePackages = basePackages ++ [ pkgs.sysvinit ];
    };
  };

  generateSystemVInitScript = import ./generate-sysvinit-script.nix {
    inherit createSystemVInitScript;
    inherit (pkgs) stdenv;
  };

  createSystemdService = import ../systemd/create-systemd-service.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit createCredentials basePackages forceDisableUserChange;
  };

  generateSystemdService = import ./generate-systemd-service.nix {
    inherit createSystemdService;
    inherit (pkgs) stdenv writeTextFile;
  };

  createSupervisordProgram = import ../supervisord/create-supervisord-program.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit (pkgs.pythonPackages) supervisor;
    inherit createCredentials basePackages forceDisableUserChange runtimeDir;
  };

  generateSupervisordProgram = import ./generate-supervisord-program.nix {
    inherit createSupervisordProgram runtimeDir;
    inherit (pkgs) stdenv writeTextFile;
  };

  createBSDRCScript = import ../bsdrc/create-bsdrc-script.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit createCredentials forceDisableUserChange runtimeDir;

    rcSubr = import ../bsdrc/rcsubr.nix {
      inherit (pkgs) stdenv;
      inherit forceDisableUserChange;
    };
  };

  generateBSDRCScript = import ../agnostic/generate-bsdrc-script.nix {
    inherit createBSDRCScript;
    inherit (pkgs) stdenv;
  };

  createLaunchdDaemon = import ../launchd/create-launchd-daemon.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit createCredentials forceDisableUserChange;
  };

  generateLaunchdDaemon = import ../agnostic/generate-launchd-daemon.nix {
    inherit (pkgs) stdenv writeTextFile;
    inherit createLaunchdDaemon runtimeDir;
  };

  createCygrunsrvParams = import ../cygrunsrv/create-cygrunsrv-params.nix {
    inherit (pkgs) writeTextFile stdenv;
  };

  generateCygrunsrvParams = import ../agnostic/generate-cygrunsrv-params.nix {
    inherit (pkgs) stdenv writeTextFile;
    inherit createCygrunsrvParams runtimeDir;
  };
in
import ./create-managed-process.nix {
  inherit processManager;
  inherit (pkgs) stdenv;

  generateProcessFun =
    if processManager == "sysvinit" then generateSystemVInitScript
    else if processManager == "systemd" then generateSystemdService
    else if processManager == "supervisord" then generateSupervisordProgram
    else if processManager == "bsdrc" then generateBSDRCScript
    else if processManager == "launchd" then generateLaunchdDaemon
    else if processManager == "cygrunsrv" then generateCygrunsrvParams
    else throw "Unknown process manager: ${processManager}";
}

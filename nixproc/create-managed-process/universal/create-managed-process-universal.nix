{pkgs, runtimeDir, logDir, tmpDir, stateDir, forceDisableUserChange ? false, processManager ? null, ids ? {}}:

let
  basePackages = [
    pkgs.coreutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.inetutils
  ];

  createCredentials = import ../../create-credentials {
    inherit (pkgs) stdenv;
    inherit ids forceDisableUserChange;
  };

  createSystemVInitScript = import ../sysvinit/create-sysvinit-script.nix {
    inherit (pkgs) stdenv writeTextFile daemon;
    inherit createCredentials runtimeDir logDir tmpDir forceDisableUserChange;

    initFunctions = import ../sysvinit/init-functions.nix {
      inherit (pkgs) stdenv fetchurl;
      inherit runtimeDir;
      basePackages = basePackages ++ [ pkgs.sysvinit ];
    };
  };

  generateSystemVInitScript = import ../sysvinit/generate-sysvinit-script.nix {
    inherit createSystemVInitScript;
    inherit (pkgs) stdenv;
  };

  createSystemdService = import ../systemd/create-systemd-service.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit createCredentials basePackages forceDisableUserChange;
  };

  generateSystemdService = import ../systemd/generate-systemd-service.nix {
    inherit createSystemdService;
    inherit (pkgs) stdenv writeTextFile;
  };

  createSupervisordProgram = import ../supervisord/create-supervisord-program.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit (pkgs.pythonPackages) supervisor;
    inherit createCredentials basePackages forceDisableUserChange runtimeDir;
  };

  generateSupervisordProgram = import ../supervisord/generate-supervisord-program.nix {
    inherit createSupervisordProgram runtimeDir;
    inherit (pkgs) stdenv writeTextFile;
  };

  createBSDRCScript = import ../bsdrc/create-bsdrc-script.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit createCredentials forceDisableUserChange runtimeDir tmpDir;

    rcSubr = import ../bsdrc/rcsubr.nix {
      inherit (pkgs) stdenv;
      inherit forceDisableUserChange;
    };
  };

  generateBSDRCScript = import ../bsdrc/generate-bsdrc-script.nix {
    inherit createBSDRCScript;
    inherit (pkgs) stdenv;
  };

  createLaunchdDaemon = import ../launchd/create-launchd-daemon.nix {
    inherit (pkgs) writeTextFile stdenv;
    inherit createCredentials forceDisableUserChange;
  };

  generateLaunchdDaemon = import ../launchd/generate-launchd-daemon.nix {
    inherit (pkgs) stdenv writeTextFile;
    inherit createLaunchdDaemon runtimeDir;
  };

  createCygrunsrvParams = import ../cygrunsrv/create-cygrunsrv-params.nix {
    inherit (pkgs) writeTextFile stdenv;
  };

  generateCygrunsrvParams = import ../cygrunsrv/generate-cygrunsrv-params.nix {
    inherit (pkgs) stdenv writeTextFile;
    inherit createCygrunsrvParams runtimeDir;
  };

  createProcessScript = import ../disnix/create-process-script.nix {
    inherit (pkgs) stdenv;
    inherit createCredentials forceDisableUserChange;
  };

  generateProcessScript = import ../disnix/generate-process-script.nix {
    inherit (pkgs) stdenv writeTextFile daemon;
    inherit createProcessScript runtimeDir logDir tmpDir forceDisableUserChange basePackages;
  };

  createDockerContainer = import ../docker/create-docker-container.nix {
    inherit (pkgs) stdenv;
  };

  generateDockerContainer = import ../docker/generate-docker-container.nix {
    inherit (pkgs) stdenv writeTextFile dockerTools findutils glibc dysnomia;
    inherit createDockerContainer basePackages runtimeDir stateDir forceDisableUserChange createCredentials;
  };

  s6-rc = import ../s6-rc {
    inherit (pkgs) stdenv;
    inherit createCredentials;
  };

  generateS6Service = import ../s6-rc/generate-s6-service.nix {
    inherit (pkgs) stdenv writeTextFile execline;
    inherit s6-rc tmpDir runtimeDir forceDisableUserChange;
  };
in
import ../agnostic/create-managed-process.nix {
  inherit processManager;
  inherit (pkgs) stdenv;

  generators = {
    sysvinit = generateSystemVInitScript;
    systemd = generateSystemdService;
    supervisord = generateSupervisordProgram;
    bsdrc = generateBSDRCScript;
    launchd = generateLaunchdDaemon;
    cygrunsrv = generateCygrunsrvParams;
    disnix = generateProcessScript;
    docker = generateDockerContainer;
    s6-rc = generateS6Service;
  };
}

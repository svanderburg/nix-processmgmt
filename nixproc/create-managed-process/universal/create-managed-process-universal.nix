{pkgs, runtimeDir, logDir, tmpDir, stateDir, forceDisableUserChange ? false, processManager ? null, ids ? {}}:

let
  basePackages = [
    pkgs.coreutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.inetutils
  ];

  createCredentials = import ../../create-credentials {
    inherit (pkgs) stdenv lib;
    inherit ids forceDisableUserChange;
  };

  createSystemVInitScript = import ../../backends/sysvinit/create-sysvinit-script.nix {
    inherit (pkgs) stdenv lib writeTextFile daemon;
    inherit createCredentials runtimeDir logDir tmpDir forceDisableUserChange;

    initFunctions = import ../../backends/sysvinit/init-functions.nix {
      inherit (pkgs) stdenv fetchurl;
      inherit runtimeDir;
      basePackages = basePackages ++ [ pkgs.sysvinit ];
    };
  };

  generateSystemVInitScript = import ../../backends/sysvinit/generate-sysvinit-script.nix {
    inherit createSystemVInitScript;
    inherit (pkgs) lib;
  };

  createSystemdService = import ../../backends/systemd/create-systemd-service.nix {
    inherit (pkgs) writeTextFile stdenv lib;
    inherit createCredentials basePackages forceDisableUserChange;
  };

  generateSystemdService = import ../../backends/systemd/generate-systemd-service.nix {
    inherit createSystemdService;
    inherit (pkgs) stdenv lib writeTextFile;
  };

  createSupervisordProgram = import ../../backends/supervisord/create-supervisord-program.nix {
    inherit (pkgs) writeTextFile stdenv lib;
    inherit (pkgs.python3Packages) supervisor;
    inherit createCredentials basePackages forceDisableUserChange runtimeDir;
  };

  generateSupervisordProgram = import ../../backends/supervisord/generate-supervisord-program.nix {
    inherit createSupervisordProgram runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv lib writeTextFile;
  };

  createBSDRCScript = import ../../backends/bsdrc/create-bsdrc-script.nix {
    inherit (pkgs) writeTextFile stdenv lib;
    inherit createCredentials forceDisableUserChange runtimeDir tmpDir;

    rcSubr = import ../../backends/bsdrc/rcsubr.nix {
      inherit (pkgs) stdenv;
      inherit forceDisableUserChange;
    };
  };

  generateBSDRCScript = import ../../backends/bsdrc/generate-bsdrc-script.nix {
    inherit createBSDRCScript;
    inherit (pkgs) lib;
  };

  createLaunchdDaemon = import ../../backends/launchd/create-launchd-daemon.nix {
    inherit (pkgs) writeTextFile stdenv lib;
    inherit createCredentials forceDisableUserChange;
  };

  generateLaunchdDaemon = import ../../backends/launchd/generate-launchd-daemon.nix {
    inherit (pkgs) stdenv writeTextFile lib;
    inherit createLaunchdDaemon runtimeDir forceDisableUserChange;
  };

  createCygrunsrvParams = import ../../backends/cygrunsrv/create-cygrunsrv-params.nix {
    inherit (pkgs) writeTextFile stdenv lib;
  };

  generateCygrunsrvParams = import ../../backends/cygrunsrv/generate-cygrunsrv-params.nix {
    inherit (pkgs) stdenv writeTextFile lib;
    inherit createCygrunsrvParams runtimeDir;
  };

  createProcessScript = import ../../backends/disnix/create-process-script.nix {
    inherit (pkgs) stdenv lib;
    inherit createCredentials forceDisableUserChange;
  };

  generateProcessScript = import ../../backends/disnix/generate-process-script.nix {
    inherit (pkgs) stdenv writeTextFile lib daemon;
    inherit createProcessScript runtimeDir logDir tmpDir forceDisableUserChange basePackages;
  };

  createDockerContainer = import ../../backends/docker/create-docker-container.nix {
    inherit (pkgs) stdenv lib;
  };

  generateDockerContainer = import ../../backends/docker/generate-docker-container.nix {
    inherit (pkgs) stdenv writeTextFile lib dockerTools findutils glibc dysnomia shadow;
    inherit createDockerContainer basePackages runtimeDir stateDir forceDisableUserChange createCredentials;
    inherit pkgs;
  };

  s6-rc = import ../../backends/s6-rc {
    inherit (pkgs) stdenv lib execline;
    inherit createCredentials logDir forceDisableUserChange;
  };

  generateS6RCService = import ../../backends/s6-rc/generate-s6-rc-service.nix {
    inherit (pkgs) stdenv writeTextFile lib execline s6;
    inherit s6-rc basePackages tmpDir runtimeDir forceDisableUserChange;
  };
in
import ../agnostic/create-managed-process.nix {
  inherit processManager;
  inherit (pkgs) stdenv;

  generators = {
    bsdrc = generateBSDRCScript;
    cygrunsrv = generateCygrunsrvParams;
    disnix = generateProcessScript;
    docker = generateDockerContainer;
    launchd = generateLaunchdDaemon;
    s6-rc = generateS6RCService;
    supervisord = generateSupervisordProgram;
    systemd = generateSystemdService;
    sysvinit = generateSystemVInitScript;
  };
}

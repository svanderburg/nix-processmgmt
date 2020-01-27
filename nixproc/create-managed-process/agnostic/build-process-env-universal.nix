{buildEnv}:
{processes, processManager}:

let
  buildSysVInitEnv = import ../sysvinit/build-sysvinit-env.nix {
    inherit buildEnv;
  };

  buildSystemdEnv = import ../systemd/build-systemd-env.nix {
    inherit buildEnv;
  };

  buildSupervisordEnv = import ../supervisord/build-supervisord-env.nix {
    inherit buildEnv;
  };

  buildBSDRCEnv = import ../bsdrc/build-bsdrc-env.nix {
    inherit buildEnv;
  };

  buildLaunchdEnv = import ../launchd/build-launchd-env.nix {
    inherit buildEnv;
  };

  buildCygrunsrvEnv = import ../cygrunsrv/build-cygrunsrv-env.nix {
    inherit buildEnv;
  };

  buildProcessEnvFun =
    if processManager == "sysvinit" then buildSysVInitEnv
    else if processManager == "systemd" then buildSystemdEnv
    else if processManager == "supervisord" then buildSupervisordEnv
    else if processManager == "bsdrc" then buildBSDRCEnv
    else if processManager == "launchd" then buildLaunchdEnv
    else if processManager == "cygrunsrv" then buildCygrunsrvEnv
    else throw "Unknown process manager: ${processManager}";
in
buildProcessEnvFun {
  inherit processes;
}

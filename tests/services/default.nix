{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, processManagers ? [ "supervisord" "sysvinit" "systemd" "docker" "disnix" "s6-rc" ]
, profiles ? [ "privileged" "unprivileged" ]
}:

let
  testService = import ../../nixproc/test-driver/universal.nix {
    inherit system;
  };
in
{
  docker = import ./docker {
    inherit pkgs processManagers profiles testService;
  };

  nginx-reverse-proxy-hostbased = import ./nginx-reverse-proxy-hostbased {
    inherit pkgs processManagers profiles testService;
  };

  s6-svscan = import ./s6-svscan {
    inherit pkgs processManagers profiles testService;
  };

  supervisord = import ./supervisord {
    inherit pkgs processManagers profiles testService;
  };
}

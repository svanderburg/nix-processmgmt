{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
}:

rec {
  common = import ./common {
    inherit (pkgs) stdenv getopt;
  };

  generate-config = import ./generate-config {
    inherit (pkgs) stdenv getopt;
  };

  bsdrc = import ./bsdrc {
    inherit (pkgs) stdenv getopt;
  };

  cygrunsrv = import ./cygrunsrv {
    inherit (pkgs) stdenv getopt;
  };

  disnix = import ./disnix {
    inherit (pkgs) stdenv getopt;
  };

  docker = import ./docker {
    inherit (pkgs) stdenv getopt;
  };

  idassign = import ./idassign {
    inherit (pkgs) stdenv getopt;
  };

  launchd = import ./launchd {
    inherit (pkgs) stdenv getopt;
  };

  s6-rc = import ./s6-rc {
    inherit (pkgs) stdenv getopt;
  };

  supervisord = import ./supervisord {
    inherit (pkgs) stdenv getopt;
  };

  systemd = import ./systemd {
    inherit (pkgs) stdenv getopt;
  };

  sysvinit = import ./sysvinit {
    inherit (pkgs) stdenv getopt;
  };
}

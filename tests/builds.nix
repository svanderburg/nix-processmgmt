{pkgs ? import <nixpkgs> {}}:

let
  nix-processmgmt = ./..;

  backends = [ "bsdrc" "cygrunsrv" "disnix" "docker" "launchd" "s6-rc" "supervisord" "systemd" "sysvinit" ];
in
pkgs.lib.genAttrs backends (backend: import "${nix-processmgmt}/nixproc/backends/${backend}/build-${backend}-env.nix" ({
  exprFile = ../examples/webapps-agnostic/processes.nix;
} // pkgs.lib.optionalAttrs (backend == "disnix") {
  disnixDataDir = "${pkgs.disnix}/share/disnix";
}))

{ lib, pkgs, ... }:

let
  syndicate-server = pkgs.syndicate-server or (let
    repo = pkgs.fetchFromGitea {
      domain = "git.syndicate-lang.org";
      owner = "ehmry";
      repo = "syndicate-flake";
      rev = "e28f71ba8878478cc160bd901da2f7b9bee29a5f";
      hash = "sha256-YaHKplVpnaL95Xwv7SYUKvNssiulLQmIAF/G78g9KZc=";
    };
    pkgs' = import repo { inherit pkgs; };
  in pkgs'.syndicate-server);

  synit = pkgs.fetchFromGitea {
    domain = "git.syndicate-lang.org";
    owner = "synit";
    repo = "synit";
    rev = "a2ecd8a4e441f8622a57a99987cb0aa5be9e1dcd";
    hash = "sha256-M79AJ8/Synzm4CYkt3+GYViJLJcuYBW+x32Vfy+oFUM=";
  };

in {
  networking.localCommands = ''
    echo '<run-service <milestone network>>' > \
      /run/etc/syndicate/core/milestone-network.pr
  '';

  systemd.services.syndicate-server = {
    description = "Syndicate dataspace server";
    wantedBy = [ "basic.target" ];
    before = [ "network.target" ];
    preStart = ''
      mkdir -p \
        "/etc/syndicate/services" \
        "/run/etc/syndicate/core" \
        "/run/etc/syndicate/services" \

      ${lib.getExe pkgs.rsync} -r \
        --exclude 001-console-getty.pr \
        --exclude configdirs.pr \
        --exclude eudev.pr \
        --exclude hostname.pr \
        --exclude services \
        "${synit}/packaging/packages/synit-config/files/etc/syndicate/" \
        "/etc/syndicate"
      echo '<require-service <config-watcher "/run/etc/syndicate/core" $.>>' > \
        /etc/syndicate/core/configdirs.pr
      echo '<require-service <config-watcher "/run/etc/syndicate/services" $.>>' > \
        /etc/syndicate/services/configdirs.pr
    '';
    serviceConfig = {
      ExecStart =
        "${lib.getExe syndicate-server} --no-banner --config /etc/syndicate";
    };
  };
}

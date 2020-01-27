let
  nixproc-generate-config = (import ../../tools {}).generate-config;
in
{
  test1 = {pkgs, ...}:

  {
    dysnomia = {
      extraContainerProperties = {
        managed-process = {
          processManager = "systemd";
          NIX_PATH = "/root/.nix-defexpr/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
        };
      };
    };

    services.disnix.enable = true;
    services.openssh.enable = true;
    networking.firewall.enable = false;
    environment.systemPackages = [ pkgs.pythonPackages.supervisor nixproc-generate-config ];
  };

  test2 = {pkgs, ...}:

  {
    dysnomia = {
      extraContainerProperties = {
        managed-process = {
          processManager = "sysvinit";
          NIX_PATH = "/root/.nix-defexpr/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
        };
      };

    };

    services.disnix.enable = true;
    services.openssh.enable = true;
    networking.firewall.enable = false;
    environment.systemPackages = [ pkgs.pythonPackages.supervisor nixproc-generate-config ];
  };
}

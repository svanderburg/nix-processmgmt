{
  test1 = {pkgs, ...}:

  {
    services.disnix.enable = true;
    services.openssh.enable = true;
    networking.firewall.enable = false;
  };

  test2 = {pkgs, ...}:

  {
    services.disnix.enable = true;
    services.openssh.enable = true;
    networking.firewall.enable = false;
  };
}

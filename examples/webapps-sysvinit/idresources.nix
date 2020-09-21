rec {
  webappPorts = {
    min = 5000;
    max = 6000;
  };

  nginxPorts = {
    min = 8080;
    max = 9000;
  };

  uids = {
    min = 2000;
    max = 3000;
  };

  gids = uids;
}

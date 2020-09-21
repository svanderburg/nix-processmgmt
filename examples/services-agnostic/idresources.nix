rec {
  uids = {
    min = 2000;
    max = 3000;
  };

  gids = uids;

  httpPorts = {
    min = 8080;
    max = 8085;
  };

  httpsPorts = {
    min = 8443;
    max = 8448;
  };

  tomcatServerPorts = {
    min = 8005;
    max = 8008;
  };

  tomcatAJPPorts = {
    min = 8009;
    max = 8012;
  };

  mysqlPorts = {
    min = 3306;
    max = 3406;
  };

  postgresqlPorts = {
    min = 5432;
    max = 5532;
  };

  mongodbPorts = {
    min = 27017;
    max = 27117;
  };

  inetHTTPPorts = {
    min = 9001;
    max = 9091;
  };

  svnPorts = {
    min = 3690;
    max = 3790;
  };

  influxdbPorts = {
    min = 8086;
    max = 8096;
    step = 3;
  };
}

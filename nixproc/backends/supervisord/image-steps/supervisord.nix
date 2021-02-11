{pkgs, common, input, result}:

result // {
  contents = result.contents or [] ++ [ pkgs.pythonPackages.supervisor ];
  config = result.config or {} // {
    Cmd = [ "${pkgs.pythonPackages.supervisor}/bin/supervisord" "--nodaemon" "--configuration" "/etc/supervisor/supervisord.conf" "--logfile" "/var/log/supervisord.log" "--pidfile" "/var/run/supervisord.pid" ];
  };
}

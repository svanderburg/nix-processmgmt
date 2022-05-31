{pkgs, common, input, result}:

result // {
  contents = result.contents or [] ++ [ pkgs.python3Packages.supervisor ];
  config = result.config or {} // {
    Cmd = [ "${pkgs.python3Packages.supervisor}/bin/supervisord" "--nodaemon" "--configuration" "/etc/supervisor/supervisord.conf" "--logfile" "/var/log/supervisord.log" "--pidfile" "/var/run/supervisord.pid" ];
  };
}

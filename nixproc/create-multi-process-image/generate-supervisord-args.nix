{pkgs, system, exprFile, stateDir, runtimeDir, forceDisableUserChange, extraParams}:

let
  profile = import ../create-managed-process/supervisord/build-supervisord-env.nix {
    inherit pkgs system exprFile extraParams stateDir runtimeDir forceDisableUserChange;
  };
in
{
  runAsRoot = ''
    ln -s ${profile} /etc/supervisor
  '';
  contents = [ pkgs.pythonPackages.supervisor ];
  cmd = [ "${pkgs.pythonPackages.supervisor}/bin/supervisord" "--nodaemon" "--configuration" "/etc/supervisor/supervisord.conf" "--logfile" "/var/log/supervisord.log" "--pidfile" "/var/run/supervisord.pid" ];
  credentialsSpec = profile;
}

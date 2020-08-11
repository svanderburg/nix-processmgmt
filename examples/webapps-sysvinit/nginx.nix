{createSystemVInitScript, stdenv, nginx, stateDir, forceDisableUserChange}:
{configFile, dependencies ? [], instanceSuffix ? "", instanceName ? "nginx${instanceSuffix}"}:

let
  user = instanceName;
  group = instanceName;
  nginxLogDir = "${stateDir}/logs";
in
createSystemVInitScript {
  name = instanceName;
  description = "Nginx";
  initialize = ''
    mkdir -p ${nginxLogDir}
    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${nginxLogDir}
    ''}
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile "-p" stateDir ];
  runlevels = [ 3 4 5 ];

  inherit dependencies instanceName;

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "Nginx user";
      };
    };
  };
}

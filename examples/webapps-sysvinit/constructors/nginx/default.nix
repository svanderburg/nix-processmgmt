{createSystemVInitScript, lib, nginx, stateDir, runtimeDir, cacheDir, forceDisableUserChange}:
{configFile, dependencies ? [], instanceSuffix ? "", instanceName ? "nginx${instanceSuffix}"}:

let
  user = instanceName;
  group = instanceName;
  nginxLogDir = "${stateDir}/logs";
  nginxCacheDir = "${cacheDir}/${instanceName}";
in
createSystemVInitScript {
  description = "Nginx";

  initialize = ''
    mkdir -p ${nginxLogDir}
    mkdir -p ${nginxCacheDir}

    ${lib.optionalString (!forceDisableUserChange) ''
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

{createManagedProcess, stdenv, nginx, stateDir, runtimeDir, cacheDir, forceDisableUserChange}:
{configFile, dependencies ? [], instanceSuffix ? "", instanceName ? "nginx${instanceSuffix}"}:

let
  user = instanceName;
  group = instanceName;

  nginxStateDir = "${stateDir}/${instanceName}";
  nginxLogDir = "${nginxStateDir}/logs";
  nginxCacheDir = "${cacheDir}/${instanceName}";
in
createManagedProcess {
  name = instanceName;
  description = "Nginx";
  initialize = ''
    mkdir -p ${nginxLogDir}
    mkdir -p ${nginxCacheDir}
    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${nginxLogDir}
      chown ${user}:${group} ${nginxCacheDir}
    ''}
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-p" "${nginxStateDir}" "-c" configFile ];
  foregroundProcessExtraArgs = [ "-g" "daemon off;" ];
  daemonExtraArgs = [ "-g" "pid ${runtimeDir}/${instanceName}.pid;" ];

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

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

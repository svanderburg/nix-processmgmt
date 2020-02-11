{createManagedProcess, stdenv, nginx, stateDir, runtimeDir, forceDisableUserChange}:
{configFile, dependencies ? [], instanceSuffix ? ""}:

let
  instanceName = "nginx${instanceSuffix}";
  user = instanceName;
  group = instanceName;
  nginxLogDir = "${stateDir}/${instanceName}/logs";
in
createManagedProcess {
  name = instanceName;
  description = "Nginx";
  initialize = ''
    mkdir -p ${nginxLogDir}
    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${nginxLogDir}
    ''}
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-p" "${stateDir}/${instanceName}" "-c" configFile ];
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

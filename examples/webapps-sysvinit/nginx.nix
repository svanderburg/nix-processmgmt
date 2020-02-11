{createSystemVInitScript, nginx, stateDir}:
{configFile, dependencies ? [], instanceSuffix ? ""}:

let
  instanceName = "nginx${instanceSuffix}";
  user = instanceName;
  group = instanceName;
  nginxLogDir = "${stateDir}/${instanceName}/logs";
in
createSystemVInitScript {
  name = instanceName;
  description = "Nginx";
  initialize = ''
    mkdir -p ${nginxLogDir}
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

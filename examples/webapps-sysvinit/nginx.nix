{createSystemVInitScript, nginx, configFile, stateDir, dependencies ? [], instanceSuffix ? ""}:

let
  instanceName = "nginx${instanceSuffix}";
in
createSystemVInitScript {
  name = instanceName;
  description = "Nginx";
  initialize = ''
    mkdir -p ${stateDir}/logs
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile "-p" stateDir ];
  runlevels = [ 3 4 5 ];

  inherit dependencies instanceName;
}

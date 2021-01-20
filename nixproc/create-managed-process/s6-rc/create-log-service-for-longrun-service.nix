{stdenv, execline, logDir, logDirUser, logDirGroup, forceDisableUserChange}:
{name}:

let
  serviceName = "${name}-log";

  util = import ./util.nix {
    inherit (stdenv) lib;
  };

  serviceLogDir = "${logDir}/s6-log/${name}";

  notificationFd = 3;
in
stdenv.mkDerivation {
  name = serviceName;
  buildCommand = ''
    mkdir -p $out/etc/s6/sv/${serviceName}
    cd $out/etc/s6/sv/${serviceName}
  ''
  + util.generateStringProperty { value = "longrun"; filename = "type"; }
  + ''
    cat > run <<EOF
    #!${execline}/bin/execlineb -P

    foreground { mkdir -p ${serviceLogDir} }
    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      foreground { chown -R ${logDirUser}:${logDirGroup} ${serviceLogDir} }
      s6-setuidgid ${logDirUser}
    ''}
    exec -c s6-log -d${toString notificationFd} ${serviceLogDir}
    EOF
  ''
  + util.generateStringProperty { value = "${name}-srv"; filename = "consumer-for"; }
  + util.generateIntProperty { value = notificationFd; filename = "notification-fd"; }
  + util.generateStringProperty { value = name; filename = "pipeline-name"; };
}

{createManagedProcess, s6, execline, runtimeDir}:

{ instanceSuffix ? ""
, instanceName ? "s6-svscan${instanceSuffix}"
, scanDir ? "${runtimeDir}/service${instanceSuffix}"
, logUser ? "s6-log${instanceSuffix}"
, logGroup ? "s6-log${instanceSuffix}"
}:

createManagedProcess {
  inherit instanceName;

  path = [ s6 execline ];
  foregroundProcess = "${s6}/bin/s6-svscan";
  args = [ scanDir ];
  initialize = ''
    mkdir -p ${scanDir}
  '';

  credentials = {
    groups = {
      "${logGroup}" = {};
    };
    users = {
      "${logUser}" = {
        group = logGroup;
        description = "s6-log user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

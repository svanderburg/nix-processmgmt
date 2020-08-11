{createManagedProcess, stdenv, mysql, stateDir, runtimeDir, forceDisableUserChange}:
{port ? 3306, instanceSuffix ? "", instanceName ? "mysqld${instanceSuffix}", postInstall ? ""}:

let
  dataDir = "${stateDir}/db/${instanceName}";
  instanceRuntimeDir = "${runtimeDir}/${instanceName}";
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  name = instanceName;
  inherit instanceName postInstall;

  initialize = ''
    mkdir -m0700 -p ${dataDir}
    mkdir -m0700 -p ${instanceRuntimeDir}

    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${dataDir}
      chown ${user}:${group} ${instanceRuntimeDir}
    ''}

    if [ ! -e "${dataDir}/mysql" ]
    then
        ${mysql}/bin/mysql_install_db --basedir=${mysql} --datadir=${dataDir} ${if forceDisableUserChange then "" else "--user=${user}"}
    fi
  '';

  foregroundProcess = "${mysql}/bin/mysqld";
  foregroundProcessArgs = [ "--basedir" mysql "--datadir" dataDir "--port" port "--socket" "${instanceRuntimeDir}/${instanceName}.sock" ]
    ++ stdenv.lib.optionals (!forceDisableUserChange) [ "--user" user ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "MySQL user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

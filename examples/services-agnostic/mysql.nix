{createManagedProcess, stdenv, mysql, stateDir, runtimeDir, forceDisableUserChange}:
{port ? 3306, instanceSuffix ? ""}:

let
  instanceName = "mysqld${instanceSuffix}";
  dataDir = "${stateDir}/db/${instanceName}";
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  name = instanceName;
  inherit instanceName user;

  initialize = ''
    mkdir -m0700 -p ${dataDir}
    mkdir -m0700 -p ${runtimeDir}

    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${dataDir}
    ''}

    if [ ! -e "${dataDir}/mysql" ]
    then
        ${mysql}/bin/mysql_install_db --basedir=${mysql} --datadir=${dataDir} ${if forceDisableUserChange then "" else "--user=${user}"}
    fi
  '';

  foregroundProcess = "${mysql}/bin/mysqld";
  foregroundProcessArgs = [ "--basedir" mysql "--datadir" dataDir "--port" port "--socket" "${runtimeDir}/${instanceName}.sock" ]
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

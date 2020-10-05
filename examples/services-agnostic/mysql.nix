{createManagedProcess, stdenv, mysql, stateDir, runtimeDir, forceDisableUserChange}:
{port ? 3306, instanceSuffix ? "", instanceName ? "mysql${instanceSuffix}", postInstall ? ""}:

let
  dataDir = "${stateDir}/db/${instanceName}";

  # By default, the socket file resides in $runtimeDir/mysqld/mysqld.sock.
  # We only change the path component: 'mysqld' into the instance name if no
  # instanceSuffix parameter is specified. Otherwise, we append the
  # instanceSuffix to 'mysqld'.
  #
  # This construction is used to allow the mysql client executable to work
  # without a socket parameter for the default configuration.

  instanceRuntimeDir =
    if instanceName != "mysql" && instanceSuffix == "" then "${runtimeDir}/${instanceName}"
    else "${runtimeDir}/mysqld${instanceSuffix}";

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
  foregroundProcessArgs = [ "--basedir" mysql "--datadir" dataDir "--port" port "--socket" "${instanceRuntimeDir}/mysqld.sock" ]
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

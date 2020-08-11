{createManagedProcess, stdenv, postgresql, stateDir, runtimeDir, forceDisableUserChange}:
{port ? 5432, instanceSuffix ? "", instanceName ? "postgresql${instanceSuffix}"}:

let
  dataDir = "${stateDir}/db/${instanceName}/data";
  socketDir = "${runtimeDir}/${instanceName}";
  user = instanceName;
  group = instanceName;
in
createManagedProcess rec {
  name = instanceName;
  inherit instanceName user;
  initialize = ''
    mkdir -m0700 -p ${socketDir}
    mkdir -m0700 -p ${dataDir}

    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${socketDir}
      chown ${user}:${group} ${dataDir}
    ''}

    if [ ! -e "${dataDir}/PG_VERSION" ]
    then
        ${postgresql}/bin/initdb -D ${dataDir} --no-locale
    fi
  '';

  process = "${postgresql}/bin/postgres";
  args = [ "-D" dataDir "-p" port "-k" socketDir ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "PostgreSQL user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];

      instructions.start = {
        activity = "Starting";
        instruction = ''
          ${initialize}
          ${postgresql}/bin/pg_ctl -D ${dataDir} -o "-p ${toString port} -k ${socketDir}" start
        '';
      };
    };
  };
}

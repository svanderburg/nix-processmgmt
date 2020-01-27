{createManagedProcess, stdenv, tomcat, jre, stateDir, runtimeDir, tmpDir, forceDisableUserChange}:
{instanceSuffix ? "", tomcatConfigFiles}:

let
  instanceName = "tomcat${instanceSuffix}";
  baseDir = "${stateDir}/${instanceName}";
  user = instanceName;
  group = instanceName;
  pidFile = "${runtimeDir}/${instanceName}.pid";
in
createManagedProcess rec {
  name = "tomcat";
  inherit instanceName user pidFile;
  process = "${tomcat}/bin/catalina.sh";
  args = [ "run" ];
  environment = {
    JRE_HOME = jre;
    CATALINA_TMPDIR = tmpDir;
    CATALINA_BASE = baseDir;
    CATALINA_PID = pidFile;
  };
  initialize = ''
    if [ ! -d "${baseDir}" ]
    then
        mkdir -p ${baseDir}/logs
        cd ${baseDir}

        cp -av ${tomcatConfigFiles}/* .
        chmod -R u+w .

        ${stdenv.lib.optionalString (!forceDisableUserChange) ''
          chown -R ${user}:${group} ${baseDir}
        ''}
    fi
  '';

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "Tomcat user";
      };
    };
  };

  overrides = {
    sysvinit = {
      instructions.start = {
        activity = "Starting";
        instruction = ''
          ${initialize}
          ${tomcat}/bin/startup.sh
        '';
      };
      runlevels = [ 3 4 5 ];
    };
  };
}

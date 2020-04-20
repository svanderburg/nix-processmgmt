{createManagedProcess, stdenv, tomcat, jre, stateDir, runtimeDir, tmpDir, forceDisableUserChange, commonLibs ? []}:
{instanceSuffix ? "", tomcatConfigFiles, postInstall ? ""}:

let
  instanceName = "tomcat${instanceSuffix}";
  baseDir = "${stateDir}/${instanceName}";
  user = instanceName;
  group = instanceName;
  pidFile = "${runtimeDir}/${instanceName}.pid";
in
createManagedProcess rec {
  name = instanceName;
  inherit instanceName user pidFile postInstall;

  process = "${tomcat}/bin/catalina.sh";
  args = [ "run" ];
  environment = {
    JRE_HOME = jre;
    CATALINA_TMPDIR = tmpDir;
    CATALINA_BASE = baseDir;
    CATALINA_PID = pidFile;
  };
  initialize = ''
    if [ ! -d "${baseDir}/logs" ]
    then
        mkdir -p ${baseDir}/logs
        cd ${baseDir}

        cp -av ${tomcatConfigFiles}/* .
        chmod -R u+w .

        mkdir -p ${baseDir}/lib

        # Symlink all the given common libs files or paths into the lib/ directory
        for i in ${tomcat} ${toString commonLibs}
        do
            if [ -f "$i" ]
            then
                # If the given web application is a file, symlink it into the common/lib/ directory
                ln -sfn $i ${baseDir}/lib/$(basename $i)
            elif [ -d "$i" ]
            then
                # If the given web application is a directory, then iterate over the files
                # in the special purpose directories and symlink them into the tomcat tree

                for j in $i/lib/*
                do
                    ln -sfn $j ${baseDir}/lib/$(basename $j)
               done
            fi
        done

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
        homeDir = baseDir;
        createHomeDir = true;
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

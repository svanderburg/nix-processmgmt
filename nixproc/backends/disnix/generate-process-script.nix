{ createProcessScript, writeTextFile, stdenv, lib, daemon, basePackages
, runtimeDir, logDir, tmpDir, forceDisableUserChange
}:

let
  daemonPkg = daemon; # Circumvent name conflict with the parameter in the next function header
in

{ name
, description
, initialize
, daemon
, daemonArgs
, instanceName
, pidFile
, foregroundProcess
, foregroundProcessArgs
, path
, environment
, directory
, umask
, nice
, user
, dependencies
, credentials
, overrides
, postInstall
}:

let
  util = import ../util {
    inherit lib;
  };

  _environment = util.appendPathToEnvironment {
    inherit environment;
    path = basePackages ++ [ daemonPkg ] ++ path;
  };

  _user = util.determineUser {
    inherit user forceDisableUserChange;
  };

  pidFilesDir = util.determinePIDFilesDir {
    inherit user runtimeDir tmpDir; # We can't use _user because we want to keep the path convention the same
  };

  _pidFile = util.autoGeneratePIDFilePath {
    inherit pidFile instanceName pidFilesDir;
  };

  invocationCommand =
    if daemon != null then util.invokeDaemon {
      process = daemon;
      args = daemonArgs;
      su = "su";
      user = _user;
    }
    else if foregroundProcess != null then util.daemonizeForegroundProcess {
      daemon = "daemon";
      process = foregroundProcess;
      args = foregroundProcessArgs;
      pidFile = _pidFile;
      user = _user;
      outputLogFile = util.autoGenerateDaemonLogFilePath {
        inherit name instanceName logDir tmpDir;
        user = _user;
        enableDaemonOutputLogging = true;
      };
      inherit pidFilesDir;
    }
    else throw "I don't know how to start this process!";

  generatedTargetSpecificArgs = {
    inherit name dependencies credentials postInstall;

    process = writeTextFile {
      name = "${name}-process-wrapper";
      executable = true;
      text = ''
        #! ${stdenv.shell} -e
      ''
      + util.printShellEnvironmentVariables {
        environment = _environment;
        allowSystemPath = true;
      }
      + lib.optionalString (umask != null) ''
        umask ${umask}
      ''
      + lib.optionalString (initialize != null) ''
        ${initialize}
      ''
      + lib.optionalString (directory != null) ''
        cd ${directory}
      ''
      + "exec ${lib.optionalString (nice != null) "nice -n ${toString nice}"} ${invocationCommand}";
    };
  } // lib.optionalAttrs (_pidFile != null) {
    pidFile = _pidFile;
  };

  targetSpecificArgs =
    if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
    else lib.recursiveUpdate generatedTargetSpecificArgs overrides;
in
createProcessScript targetSpecificArgs

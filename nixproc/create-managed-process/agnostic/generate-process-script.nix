{ createProcessScript, writeTextFile, stdenv, daemon, basePackages
, runtimeDir, tmpDir, forceDisableUserChange
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
    inherit (stdenv) lib;
  };

  _path = basePackages ++ [ daemonPkg ] ++ path;

  _environment = {
    PATH = builtins.concatStringsSep ":" (map (package: "${package}/bin") _path) + ":$PATH";
  } // environment;

  _pidFile =
    if pidFile == null
      then if instanceName == null
        then null
        else if user == null || user == "root"
          then "${runtimeDir}/${instanceName}.pid"
          else "${tmpDir}/${instanceName}.pid"
    else pidFile;

  _user = util.determineUser {
    inherit user forceDisableUserChange;
  };

  pidFilesDir = util.determinePIDFilesDir {
    user = _user;
    inherit runtimeDir tmpDir;
  };
in
createProcessScript (stdenv.lib.recursiveUpdate ({
  inherit name dependencies credentials postInstall;

  process = writeTextFile {
    name = "${name}-process-wrapper";
    executable = true;
    text = ''
      #! ${stdenv.shell} -e
    ''
    + stdenv.lib.concatMapStrings (name:
        let
          value = builtins.getAttr name _environment;
        in
        ''
          export ${name}=${if name == "PATH" then value else stdenv.lib.escapeShellArg value}
        ''
      ) (builtins.attrNames _environment)
    + stdenv.lib.optionalString (umask != null) ''
      umask ${umask}
    ''
    + stdenv.lib.optionalString (directory != null) ''
      cd ${directory}
    ''
    + stdenv.lib.optionalString (nice != null) ''
      nice -n ${toString nice}
    ''
    + stdenv.lib.optionalString (initialize != null) ''
      ${initialize}
    ''
    + (if (daemon != null) then ''
      exec ${stdenv.lib.optionalString (_user != null) "su ${_user} -c '"} ${daemon} ${stdenv.lib.escapeShellArgs daemonArgs} ${stdenv.lib.optionalString (_user != null) "'"}
    '' else if (foregroundProcess != null) then util.daemonizeForegroundProcess {
      daemon = "daemon";
      process = foregroundProcess;
      args = foregroundProcessArgs;
      pidFile = _pidFile;
      user = _user;
      inherit pidFilesDir;
    }
    else throw "I don't know how to start this process!");
  };
} // stdenv.lib.optionalAttrs (_pidFile != null) {
  pidFile = _pidFile;
}) overrides)

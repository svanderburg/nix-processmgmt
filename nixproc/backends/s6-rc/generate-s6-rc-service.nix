{ s6, s6-rc, basePackages, stdenv, lib, writeTextFile, execline, tmpDir, runtimeDir, forceDisableUserChange }:

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

  s6-rcBasePackages = basePackages ++ [ execline s6 ];

  _environment = util.appendPathToEnvironment {
    inherit environment;
    path = s6-rcBasePackages ++ path;
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

  envFile =
    if _environment == {} then null
    else writeTextFile {
      name = "envfile";
      text = lib.concatMapStrings (envName:
        let
          envValue = builtins.getAttr envName _environment;
        in
        ''
          ${envName}=${toString envValue}
        ''
      ) (builtins.attrNames _environment);
    };

  initializeScript =
    if initialize == "" then null
    else writeTextFile {
      name = "initialize";
      text = ''
        #! ${stdenv.shell} -e
        ${initialize}
      '';
      executable = true;
    };

  configurationScript = ''
    #!${execline}/bin/execlineb -P

  ''
  + lib.optionalString (envFile != null) ''
    envfile ${envFile}
  ''
  + lib.optionalString (initializeScript != null) ''
    foreground { ${initializeScript} }
  ''
  + lib.optionalString (umask != null) ''
    execline-umask ${umask}
  ''
  + lib.optionalString (directory != null) ''
    execline-cd ${directory}
  ''
  + lib.optionalString (_user != null) ''
    s6-setuidgid ${_user}
  ''
  + lib.optionalString (nice != null) ''
    nice -n ${toString nice}
  ''
  # Always forward standard error so that it can be captured by the s6-log service
  + ''
    fdmove -c 2 1
  '';

  escapeArgs = args:
    lib.concatMapStringsSep " " (arg: "\"${lib.replaceStrings ["\""] ["\\\""] (toString arg)}\"") args;
in
if foregroundProcess != null then
  let
    generatedTargetSpecificArgs = {
      inherit name dependencies credentials postInstall;
      run = writeTextFile {
        name = "run";
        text = ''
          ${configurationScript}
          exec ${foregroundProcess} ${escapeArgs foregroundProcessArgs}
        '';
      };
    };

    targetSpecificArgs =
      if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
      else lib.recursiveUpdate generatedTargetSpecificArgs overrides;
  in
  s6-rc.createLongRunService targetSpecificArgs
else if daemon != null then
  let
    generatedTargetSpecificArgs = {
      inherit name dependencies credentials postInstall;
      up = writeTextFile {
        name = "up";
        text = ''
          ${configurationScript}
          exec ${daemon} ${escapeArgs daemonArgs}
        '';
      };
      down = writeTextFile {
        name = "down";
        text = ''
          #!${execline}/bin/execlineb -P

          backtick PID { cat ${pidFile} }
          importas -i PID PID
          kill $PID
        '';
      };
    };

    targetSpecificArgs =
      if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
      else lib.recursiveUpdate generatedTargetSpecificArgs overrides;
  in
  s6-rc.createOneShotService targetSpecificArgs
else throw "No foreground process or daemon known!"

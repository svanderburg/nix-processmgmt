{ s6-rc, stdenv, writeTextFile, execline, tmpDir, runtimeDir, forceDisableUserChange }:

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

  _environment = util.appendPathToEnvironment {
    inherit environment path;
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
      text = stdenv.lib.concatMapStrings (envName:
        let
          envValue = builtins.getAttr envName _environment;
        in
        ''
          ${envName}=${toString envValue}
        ''
      ) (builtins.attrNames _environment);
    };

  initializeScript =
    if initialize == null then null
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
  + stdenv.lib.optionalString (envFile != null) ''
    envfile ${envFile}
  ''
  + stdenv.lib.optionalString (initializeScript != null) ''
    foreground { ${initializeScript} }
  ''
  + stdenv.lib.optionalString (umask != null) ''
    execline-umask ${umask}
  ''
  + stdenv.lib.optionalString (directory != null) ''
    execline-cd ${directory}
  ''
  + stdenv.lib.optionalString (_user != null) ''
    s6-setuidgid ${_user}
  ''
  + stdenv.lib.optionalString (nice != null) ''
    nice -n ${toString nice}
  '';

  escapeArgs = args:
    stdenv.lib.concatMapStringsSep " " (arg: "\"${stdenv.lib.replaceStrings ["\""] ["\\\""] (toString arg)}\"") args;
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
      else stdenv.lib.recursiveUpdate generatedTargetSpecificArgs overrides;
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

          backtick pid { cat ${pidFile} }
          kill $pid
        '';
      };
    };

    targetSpecificArgs =
      if builtins.isFunction overrides then overrides generatedTargetSpecificArgs
      else stdenv.lib.recursiveUpdate generatedTargetSpecificArgs overrides;
  in
  s6-rc.createOneShotService targetSpecificArgs
else throw "No foreground process or daemon known!"

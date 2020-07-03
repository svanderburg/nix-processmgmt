{ createDockerContainer, dockerTools, stdenv, writeTextFile, findutils, glibc, dysnomia, basePackages, runtimeDir, stateDir, forceDisableUserChange, createCredentials }:

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

# umask unsupported
# nice unsupported

let
  generateForegroundWrapper = import ./generate-foreground-wrapper.nix {
    inherit stdenv writeTextFile;
  };

  cmd = if foregroundProcess != null
    then
      if initialize == null
      then [ foregroundProcess ] ++ foregroundProcessArgs
      else
        let
          wrapper = generateForegroundWrapper ({
            wrapDaemon = false;
            executable = foregroundProcess;
            inherit name initialize runtimeDir stdenv;
          } // stdenv.lib.optionalAttrs (instanceName != null) {
            inherit instanceName;
          } // stdenv.lib.optionalAttrs (pidFile != null) {
            inherit pidFile;
          });
        in
        [ wrapper ] ++ foregroundProcessArgs
    else
      let
        wrapper = generateForegroundWrapper ({
          wrapDaemon = true;
          executable = daemon;
          inherit name initialize runtimeDir stdenv;
        } // stdenv.lib.optionalAttrs (instanceName != null) {
          inherit instanceName;
        } // stdenv.lib.optionalAttrs (pidFile != null) {
          inherit pidFile;
        });
      in
      [ wrapper ] ++ daemonArgs;

  # Remove the Nix store references so that these Nix store paths won't end up in the image.
  # Instead, we mount the host system's Nix store so that the software is still accessible inside the container.
  cmdWithoutContext = map (arg: builtins.unsafeDiscardStringContext arg) cmd;

  _path = basePackages ++ path;

  _environment = {
    PATH = builtins.concatStringsSep ":" (map(package: "${package}/bin" ) _path);
  } // environment;

  credentialsSpec = if credentials == {} || forceDisableUserChange then null else createCredentials credentials;

  _user = if forceDisableUserChange then null else user;

  dockerImage = dockerTools.buildImage (stdenv.lib.recursiveUpdate {
    inherit name;
    tag = "latest";
    runAsRoot = ''
      ${dockerTools.shadowSetup}

      ${stdenv.lib.optionalString (credentialsSpec != null) ''
        export PATH=$PATH:${findutils}/bin:${glibc.bin}/bin
        ${dysnomia}/bin/dysnomia-addgroups ${credentialsSpec}
        ${dysnomia}/bin/dysnomia-addusers ${credentialsSpec}
      ''}

      ${stdenv.lib.optionalString forceDisableUserChange ''
        groupadd -r nogroup
        useradd -r nobody -g nogroup -d /dev/null
      ''}
    '';
    config = {
      Cmd = cmdWithoutContext;
    } // stdenv.lib.optionalAttrs (_environment != {}) {
      Env = map (varName: "${varName}=${toString (builtins.getAttr varName _environment)}") (builtins.attrNames _environment);
    } // stdenv.lib.optionalAttrs (directory != null) {
      WorkingDir = directory;
    } // stdenv.lib.optionalAttrs (_user != null) {
      User = _user;
    };
  } overrides.image or {});
in
createDockerContainer (stdenv.lib.recursiveUpdate {
  inherit name dockerImage postInstall cmd dependencies;
  dockerImageTag = "${name}:latest";
  useHostNixStore = true;
  useHostNetwork = true;
  mapStateDirVolume = stateDir;
} overrides.container or {})

{ createDockerContainer, dockerTools, stdenv, lib, writeTextFile, findutils, glibc, shadow, dysnomia, pkgs, basePackages, runtimeDir, stateDir, forceDisableUserChange, createCredentials }:

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

  commonTools = (import ../../../tools {
    inherit pkgs;
  }).common;

  generateForegroundProxy = import ../util/generate-foreground-proxy.nix {
    inherit stdenv lib writeTextFile;
  };

  _user = util.determineUser {
    inherit user forceDisableUserChange;
  };

  _initialize =
    ''
      nixproc-init-state --state-dir ${stateDir} --runtime-dir ${runtimeDir}
    ''
    + lib.optionalString (!forceDisableUserChange && credentialsSpec != null) ''
      dysnomia-addgroups ${credentialsSpec}
      dysnomia-addusers ${credentialsSpec}
    ''
    + lib.optionalString (umask != null) ''
      umask ${umask}
    ''
    + initialize;

  cmd = if foregroundProcess != null
    then
      let
        wrapper = generateForegroundProxy ({
          wrapDaemon = false;
          executable = foregroundProcess;
          user = _user;
          initialize = _initialize;
          inherit name runtimeDir stdenv nice;
        } // lib.optionalAttrs (instanceName != null) {
          inherit instanceName;
        } // lib.optionalAttrs (pidFile != null) {
          inherit pidFile;
        });
      in
      [ wrapper ] ++ foregroundProcessArgs
    else
      let
        wrapper = generateForegroundProxy ({
          wrapDaemon = true;
          executable = daemon;
          user = _user;
          initialize = _initialize;
          inherit name runtimeDir stdenv nice;
        } // lib.optionalAttrs (instanceName != null) {
          inherit instanceName;
        } // lib.optionalAttrs (pidFile != null) {
          inherit pidFile;
        });
      in
      [ wrapper ] ++ daemonArgs;

  # Remove the Nix store references so that these Nix store paths won't end up in the image.
  # Instead, we mount the host system's Nix store so that the software is still accessible inside the container.
  cmdWithoutContext = map (arg: if builtins.isAttrs arg then builtins.unsafeDiscardStringContext arg else toString arg) cmd;

  # Add all packes added to PATH to the store paths making it possible to not
  # garbage collect them, but discard their context so that the packages are
  # not included in the image
  storePaths = basePackages ++ [ commonTools ]
    ++ lib.optionals (!forceDisableUserChange && credentialsSpec != null) [ shadow findutils glibc.bin dysnomia ]
    ++ path;

  _environment = util.appendPathToEnvironment {
    inherit environment;
    path = map (pathComponent: if builtins.isAttrs pathComponent then builtins.unsafeDiscardStringContext pathComponent else toString pathComponent) storePaths
      ++ [ "" ]; # Also give permission to /bin to allow any package added to contents can be used
  };

  credentialsSpec = createCredentials credentials;

  generatedDockerImageArgs = {
    inherit name;
    tag = "latest";

    runAsRoot = ''
      ${dockerTools.shadowSetup}

      # Always create these global state directories, because they are needed quite often
      mkdir -p /run /tmp
      chmod 1777 /tmp
      mkdir -p /var
      ln -sfn /run /var/run
    ''
    + lib.optionalString forceDisableUserChange ''
      groupadd -r nogroup
      useradd -r nobody -g nogroup -d /dev/null
    '';

    config = {
      Cmd = cmdWithoutContext;
    } // lib.optionalAttrs (_environment != {}) {
      Env = map (varName: "${varName}=${toString (builtins.getAttr varName _environment)}") (builtins.attrNames _environment);
    } // lib.optionalAttrs (directory != null) {
      WorkingDir = directory;
    };
  };

  dockerImageArgs =
    if overrides ? image
    then
      if builtins.isFunction overrides.image then overrides.image generatedDockerImageArgs
      else lib.recursiveUpdate generatedDockerImageArgs overrides.image
    else generatedDockerImageArgs;

  dockerImage = dockerTools.buildImage dockerImageArgs;

  generatedDockerContainerArgs = {
    inherit name dockerImage postInstall cmd storePaths dependencies;
    dockerImageTag = "${name}:latest";
    useHostNixStore = true;
    useHostNetwork = true;
    mapStateDirVolumes = [ stateDir ];
  };

  dockerContainerArgs =
    if overrides ? container
    then
      if builtins.isFunction overrides.container then overrides.container generatedDockerContainerArgs
      else lib.recursiveUpdate generatedDockerContainerArgs overrides.container
    else generatedDockerContainerArgs;
in
createDockerContainer dockerContainerArgs

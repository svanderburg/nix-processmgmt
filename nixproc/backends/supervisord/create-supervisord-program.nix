{writeTextFile, stdenv, lib, createCredentials, supervisor, basePackages, forceDisableUserChange ? false, runtimeDir}:

{
# A name that identifies the process instance
name
# Indicates whether we want to use the pidproxy
, useProxy ? false
# Command line instruction to execute
, command ? null
# Name of the PID file that contains the PID of the running process
, pidFile ? "${name}.pid"
# Specifies which packages need to be in the PATH
, path ? []
# An attribute set specifying arbitrary environment variables
, environment ? {}
# List of supervisord programs that this configuration depends on. This is used to derive the activation order.
, dependencies ? []
# Specifies which groups and users that need to be created.
, credentials ? {}
# Arbitrary commands executed after generating the configuration files
, postInstall ? ""
# The remainder of the parameters directly translate to the properties described in: http://supervisord.org/configuration.html
, ...
}@params:

let
  util = import ../util {
    inherit lib;
  };

  properties = removeAttrs params ([ "name" "command" "useProxy" "pidFile" "path" "environment" "dependencies" "credentials" "postInstall" ] ++ lib.optional forceDisableUserChange "user");

  priority = if dependencies == [] then 1
    else builtins.head (builtins.sort (a: b: a > b) (map (dependency: dependency.priority) dependencies)) + 1;

  _command = (lib.optionalString useProxy "${supervisor}/bin/pidproxy ${runtimeDir}/${pidFile} ") + command;

  _environment = util.appendPathToEnvironment {
    inherit environment;
    path = basePackages ++ path;
  };

  confFile = writeTextFile {
    name = "${name}.conf";
    text = ''
      [program:${name}]
      command=${_command}
      priority=${toString priority}
    ''
    + (if _environment == {} then "" else "environment=" + lib.concatMapStringsSep "," (name:
      let
        value = builtins.getAttr name _environment;
      in
      "${name}=\"${lib.escape [ "\"" ] (toString value)}\""
    ) (builtins.attrNames _environment)) +
    "\n"
    + lib.concatMapStrings (name:
      let
        value = builtins.getAttr name properties;
      in
      ''${name}=${toString value}
      ''
      ) (builtins.attrNames properties);
  };

  credentialsSpec = createCredentials credentials;
in
stdenv.mkDerivation {
  inherit name priority;
  buildCommand = ''
    mkdir -p $out/conf.d
    ln -s ${confFile} $out/conf.d/${name}.conf
    ln -s ${credentialsSpec}/dysnomia-support $out/dysnomia-support

    ${postInstall}
  '';
}

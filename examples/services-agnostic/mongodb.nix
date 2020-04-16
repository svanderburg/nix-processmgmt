{createManagedProcess, mongodb, runtimeDir}:
{instanceSuffix ? "", configFile, initialize ? "", postInstall ? ""}:

let
  instanceName = "mongodb${instanceSuffix}";
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  name = instanceName;
  inherit instanceName initialize postInstall;
  process = "${mongodb}/bin/mongod";
  args = [ "--config" configFile ];
  daemonExtraArgs = [ "--fork" "--pidfilepath" "${runtimeDir}/${instanceName}.pid" ];
  user = instanceName;

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "MongoDB user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

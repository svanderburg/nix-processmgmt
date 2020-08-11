{createManagedProcess, apacheHttpd, cacheDir}:
{instanceSuffix ? "", instanceName ? "httpd${instanceSuffix}", configFile, initialize ? "", postInstall ? ""}:

let
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  name = instanceName;
  inherit instanceName initialize postInstall;

  process = "${apacheHttpd}/bin/httpd";
  args = [ "-f" configFile ];
  foregroundProcessExtraArgs = [ "-DFOREGROUND" ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        homeDir = "${cacheDir}/${user}";
        description = "Apache HTTP daemon user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

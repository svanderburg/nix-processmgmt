{createManagedProcess, docker, kmod, runtimeDir, libDir}:
{instanceSuffix ? "", instanceName ? "docker${instanceSuffix}", extraArgs ? []}:

let
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  inherit instanceName;
  foregroundProcess = "${docker}/bin/dockerd";
  args = [
    "--group=${group}"
    "--host=unix://${runtimeDir}/${instanceName}.sock"
    # Add -alt suffix. We only need PID files for the backends that requires processes to daemonize on their own.
    # The `daemon` command will create PID files for them. Without the -alt suffix they will conflict causing the Docker daemon to refuse to start.
    "--pidfile=${runtimeDir}/${instanceName}-alt.pid"
    "--data-root=${libDir}/${instanceName}"
    "--exec-root=${runtimeDir}/${instanceName}"
    "--log-driver=json-file"
  ] ++ extraArgs;
  path = [ kmod ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "Docker user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

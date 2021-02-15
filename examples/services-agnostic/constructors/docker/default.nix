{createManagedProcess, docker, kmod}:

let
  user = "docker";
  group = "docker";
in
createManagedProcess {
  name = "docker";
  foregroundProcess = "${docker}/bin/dockerd";
  args = [ "--group=${group}" "--host=unix://" "--log-driver=json-file" ];
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

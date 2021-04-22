{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  pkgs = import nixpkgs {};

  dockerProcessEnv = import ../nixproc/backends/systemd/build-systemd-env.nix {
    exprFile = ../nixproc/backends/docker/test-module/processes-docker.nix;
  };

  processManagers = [ "supervisord" "sysvinit" "disnix" "s6-rc" ];
  userManagementPolicies = [ "privileged" "unprivileged" ];

  images = pkgs.lib.genAttrs processManagers (processManager:
    pkgs.lib.genAttrs userManagementPolicies (userManagementPolicy:
      import ../examples/multi-process-image {
        inherit processManager;
        forceDisableUserChange = userManagementPolicy == "unprivileged";
      }
    )
  );

  nix-processmgmt = ./..;

  tools = import ../tools {};

  env = "NIX_PATH=nixpkgs=${nixpkgs} SYSTEMD_TARGET_DIR=/etc/systemd-mutable/system";
in
makeTest {
  machine =
    {pkgs, ...}:

    {
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [ dockerProcessEnv ];
      virtualisation.writableStore = true;
      virtualisation.diskSize = 4096;
      virtualisation.memorySize = 8192;

      dysnomia = {
        enable = true;
        enableLegacyModules = false;
      };

      environment.systemPackages = [
        tools.common
        tools.systemd
        pkgs.docker
      ];
    };

  testScript = ''
    start_all()

    machine.succeed("mkdir -p /etc/systemd-mutable/system")

    # Deploy Docker as a systemd unit

    machine.succeed(
        "${env} nixproc-systemd-switch ${nix-processmgmt}/tests/processes-docker.nix"
    )

    machine.wait_for_unit("nix-process-docker")
    machine.succeed("sleep 10")

    ${pkgs.lib.concatMapStrings (processManager:
      pkgs.lib.concatMapStrings (userManagementPolicy:
        let
          image = images."${processManager}"."${userManagementPolicy}";
        in
        ''
          machine.succeed(
              "docker load -i ${image}"
          )
          machine.succeed(
              "docker run --name multiprocess --detach --rm --network host multiprocess:test"
          )
          machine.succeed("sleep 30")
          machine.succeed("curl --fail -H 'Host: webapp.local' http://localhost:8080")
          machine.succeed("docker stop multiprocess")
          machine.succeed("docker rmi multiprocess:test")
        '') userManagementPolicies
    ) processManagers}'';
}

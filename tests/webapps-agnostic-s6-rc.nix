{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  s6-svscanProcessEnv = import ../nixproc/backends/systemd/build-systemd-env.nix {
    exprFile = ../nixproc/backends/s6-rc/test-module/processes-s6-svscan.nix;
  };

  processesEnvForeground = import ../nixproc/backends/s6-rc/build-s6-rc-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
    extraParams = {
      webappMode = "foreground";
    };
  };

  processesEnvDaemon = import ../nixproc/backends/s6-rc/build-s6-rc-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
    extraParams = {
      webappMode = "daemon";
    };
  };

  processesEnvAuto = import ../nixproc/backends/s6-rc/build-s6-rc-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
  };

  processesEnvAutoUnprivileged = import ../nixproc/backends/s6-rc/build-s6-rc-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
    forceDisableUserChange = true;
  };

  processesEnvAdvanced = import ../nixproc/backends/s6-rc/build-s6-rc-env.nix {
    exprFile = ../examples/webapps-agnostic/processes-advanced.nix;
  };

  processesEnvEmpty = import ../nixproc/backends/s6-rc/build-s6-rc-env.nix {
    exprFile = null;
  };

  tools = import ../tools {};

  nix-processmgmt = ./..;

  env = "NIX_PATH=nixpkgs=${nixpkgs} SYSTEMD_TARGET_DIR=/etc/systemd-mutable/system";
in
makeTest {
  machine =
    {pkgs, ...}:

    {
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [
        s6-svscanProcessEnv
        processesEnvForeground
        processesEnvDaemon
        processesEnvAuto
        processesEnvAutoUnprivileged
        processesEnvAdvanced
        processesEnvEmpty
      ];

      virtualisation.writableStore = true;
      virtualisation.memorySize = 1024;

      boot.extraSystemdUnitPaths = [ "/etc/systemd-mutable/system" ];

      # We can't download any substitutes in a test environment. To make tests
      # faster, we disable substitutes so that Nix does not waste any time by
      # attempting to download them.
      nix.extraOptions = ''
        substitute = false
      '';

      environment.systemPackages = [
        pkgs.stdenv
        pkgs.s6
        pkgs.s6-rc
        pkgs.dysnomia
        tools.common
        tools.s6-rc
        tools.systemd
      ];
    };

  testScript = ''
    def check_nginx_redirection():
        machine.succeed(
            "curl --fail -H 'Host: webapp.local' http://localhost:8080 | grep 'listening on port: 5000'"
        )


    def check_system_unavailable():
        machine.fail("curl --fail http://localhost:8080")
        machine.fail("pgrep -f '/bin/webapp'")


    def check_nginx_multi_instance_redirection():
        machine.succeed(
            "curl --fail -H 'Host: webapp1.local' http://localhost:8080 | grep 'listening on port: 5001'"
        )
        machine.succeed(
            "curl --fail -H 'Host: webapp5.local' http://localhost:8081 | grep 'listening on port: 5005'"
        )


    start_all()

    machine.succeed("mkdir -p /etc/systemd-mutable/system")

    # Deploy s6-svscan as a systemd unit

    machine.succeed(
        "${env} nixproc-systemd-switch ${nix-processmgmt}/nixproc/backends/s6-rc/test-module/processes-s6-svscan.nix"
    )

    # Deploy the system with foreground webapp processes

    machine.succeed(
        '${env} nixproc-s6-rc-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --extra-params \'{ "webappMode" = "foreground"; }\'${""}'
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp$'")

    check_nginx_redirection()

    # Deploy the system with daemon webapp processes

    machine.succeed(
        '${env} nixproc-s6-rc-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --extra-params \'{ "webappMode" = "daemon"; }\'${""}'
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp -D$'")

    check_nginx_redirection()

    # Deploy the entire system in auto mode. Should result in foreground webapp processes

    machine.succeed(
        "${env} nixproc-s6-rc-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix"
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp$'")

    check_nginx_redirection()

    # Deploy the advanced example with multiple instances and see if it works

    machine.succeed(
        "${env} nixproc-s6-rc-switch ${nix-processmgmt}/examples/webapps-agnostic/processes-advanced.nix"
    )

    machine.succeed("sleep 1")

    check_nginx_multi_instance_redirection()

    # Deploy an instance without changing user privileges

    machine.succeed(
        "${env} nixproc-s6-rc-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --force-disable-user-change"
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u root -f '/bin/webapp$'")

    check_nginx_redirection()

    # Undeploy the system

    machine.succeed(
        "${env} nixproc-s6-rc-switch --undeploy"
    )

    check_system_unavailable()
  '';
}

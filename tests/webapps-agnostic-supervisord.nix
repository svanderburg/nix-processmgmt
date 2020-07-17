{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  supervisordProcessEnv = import ../nixproc/create-managed-process/systemd/build-systemd-env.nix {
    exprFile = ./processes-supervisord.nix;
  };

  processesEnvForeground = import ../nixproc/create-managed-process/supervisord/build-supervisord-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
    extraParams = {
      webappMode = "foreground";
    };
  };

  processesEnvDaemon = import ../nixproc/create-managed-process/supervisord/build-supervisord-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
    extraParams = {
      webappMode = "daemon";
    };
  };

  processesEnvAuto = import ../nixproc/create-managed-process/supervisord/build-supervisord-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
  };

  processesEnvAdvanced = import ../nixproc/create-managed-process/supervisord/build-supervisord-env.nix {
    exprFile = ../examples/webapps-agnostic/processes-advanced.nix;
  };

  processesEnvEmpty = import ../nixproc/create-managed-process/supervisord/build-supervisord-env.nix {
    exprFile = ../examples/webapps-agnostic/processes-empty.nix;
  };

  tools = import ../tools {};

  nix-processmgmt = ./..;

  env = "NIX_PATH=nixpkgs=${nixpkgs} SYSTEMD_TARGET_DIR=/etc/systemd-mutable/system SUPERVISORD_CONF_DIR=/var/lib/supervisord";
in
makeTest {
  machine =
    {pkgs, ...}:

    {
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [ supervisordProcessEnv processesEnvForeground processesEnvDaemon processesEnvAuto processesEnvAdvanced processesEnvEmpty ];
      virtualisation.writableStore = true;
      virtualisation.memorySize = 1024;

      # We can't download any substitutes in a test environment. To make tests
      # faster, we disable substitutes so that Nix does not waste any time by
      # attempting to download them.
      nix.extraOptions = ''
        substitute = false
      '';

      environment.systemPackages = [
        pkgs.stdenv
        pkgs.pythonPackages.supervisor
        pkgs.dysnomia
        tools.build
        tools.systemd
        tools.supervisord
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
            "curl --fail -H 'Host: webapp1.local' http://localhost:8080 | grep 'listening on port: 5000'"
        )
        machine.succeed(
            "curl --fail -H 'Host: webapp5.local' http://localhost:8081 | grep 'listening on port: 6002'"
        )


    start_all()

    machine.succeed("mkdir -p /etc/systemd-mutable/system")

    # Deploy supervisord as a systemd unit

    machine.succeed(
        "${env} nixproc-systemd-switch ${nix-processmgmt}/tests/processes-supervisord.nix"
    )

    # Deploy the system with foreground webapp processes

    machine.succeed(
        '${env} nixproc-supervisord-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --extra-params \'{ "webappMode" = "foreground"; }\'${""}'
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp$'")

    check_nginx_redirection()

    # Deploy the system with daemon webapp processes

    machine.succeed(
        '${env} nixproc-supervisord-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --extra-params \'{ "webappMode" = "daemon"; }\'${""}'
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp -D$'")

    check_nginx_redirection()

    # Deploy the entire system in auto mode. Should result in foreground webapp processes

    machine.succeed(
        "${env} nixproc-supervisord-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix"
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp$'")

    check_nginx_redirection()

    # Deploy the advanced example with multiple instances and see if it works

    machine.succeed(
        "${env} nixproc-supervisord-switch ${nix-processmgmt}/examples/webapps-agnostic/processes-advanced.nix"
    )

    machine.succeed("sleep 1")

    check_nginx_multi_instance_redirection()

    # Deploy an instance without changing user privileges

    machine.succeed(
        "${env} nixproc-supervisord-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --force-disable-user-change"
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u root -f '/bin/webapp$'")

    check_nginx_redirection()

    # Undeploy the system

    machine.succeed(
        "${env} nixproc-supervisord-switch ${nix-processmgmt}/examples/webapps-agnostic/processes-empty.nix"
    )

    check_system_unavailable()
  '';
}

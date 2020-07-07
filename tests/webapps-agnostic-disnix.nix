{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  disnixDataDir = "${pkgs.disnix}/share/disnix";

  processesEnvForeground = import ../nixproc/create-managed-process/disnix/build-disnix-env.nix {
    inherit disnixDataDir;
    exprFile = ../examples/webapps-agnostic/processes.nix;
    extraParams = {
      webappMode = "foreground";
    };
  };

  processesEnvDaemon = import ../nixproc/create-managed-process/disnix/build-disnix-env.nix {
    inherit disnixDataDir;
    exprFile = ../examples/webapps-agnostic/processes.nix;
    extraParams = {
      webappMode = "daemon";
    };
  };

  processesEnvAuto = import ../nixproc/create-managed-process/disnix/build-disnix-env.nix {
    inherit disnixDataDir;
    exprFile = ../examples/webapps-agnostic/processes.nix;
  };

  processesEnvAdvanced = import ../nixproc/create-managed-process/disnix/build-disnix-env.nix {
    inherit disnixDataDir;
    exprFile = ../examples/webapps-agnostic/processes-advanced.nix;
  };

  processesEnvNoUserChange = import ../nixproc/create-managed-process/disnix/build-disnix-env.nix {
    inherit disnixDataDir;
    exprFile = ../examples/webapps-agnostic/processes.nix;
    forceDisableUserChange = true;
  };

  processesEnvEmpty = import ../nixproc/create-managed-process/disnix/build-disnix-env.nix {
    inherit disnixDataDir;
    exprFile = ../examples/webapps-agnostic/processes-empty.nix;
  };

  tools = import ../tools {};

  nix-processmgmt = ./..;

  env = "NIX_PATH=nixpkgs=${nixpkgs} DISNIX_DATA_DIR=${disnixDataDir}";
in
makeTest {
  machine =
    {pkgs, ...}:

    {
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [ processesEnvForeground processesEnvDaemon processesEnvAuto processesEnvAdvanced processesEnvNoUserChange processesEnvEmpty ];
      virtualisation.writableStore = true;
      virtualisation.memorySize = 1024;

      users.extraUsers = {
        unprivileged = {
          uid = 1000;
          group = "users";
          shell = "/bin/sh";
          description = "Unprivileged user";
          home = "/home/unprivileged";
          createHome = true;
        };
      };

      # We can't download any substitutes in a test environment. To make tests
      # faster, we disable substitutes so that Nix does not waste any time by
      # attempting to download them.
      nix.extraOptions = ''
        substitute = false
      '';

      environment.systemPackages = [
        pkgs.stdenv
        pkgs.dysnomia
        pkgs.disnix
        tools.build
        tools.systemd
        tools.disnix
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

    # Deploy the system with foreground webapp processes

    machine.succeed(
        '${env} nixproc-disnix-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --extra-params \'{ "webappMode" = "foreground"; }\'${""}'
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp$'")

    check_nginx_redirection()

    # Deploy the system with daemon webapp processes

    machine.succeed(
        '${env} nixproc-disnix-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --extra-params \'{ "webappMode" = "daemon"; }\'${""}'
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp -D$'")

    check_nginx_redirection()

    # Deploy the entire system in auto mode. Should result in daemon webapp processes

    machine.succeed(
        "${env} nixproc-disnix-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix"
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u webapp -f '/bin/webapp -D$'")

    check_nginx_redirection()

    # Deploy the advanced example with multiple instances and see if it works

    machine.succeed(
        "${env} nixproc-disnix-switch ${nix-processmgmt}/examples/webapps-agnostic/processes-advanced.nix"
    )

    machine.succeed("sleep 1")

    check_nginx_multi_instance_redirection()

    # Deploy an instance without changing user privileges

    machine.succeed(
        "${env} nixproc-disnix-switch ${nix-processmgmt}/examples/webapps-agnostic/processes.nix --force-disable-user-change"
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u root -f '/bin/webapp -D$'")

    check_nginx_redirection()

    # Undeploy the system

    machine.succeed(
        "${env} nixproc-disnix-switch ${nix-processmgmt}/examples/webapps-agnostic/processes-empty.nix"
    )

    check_system_unavailable()
  '';
}

{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  webappUnprivileged = (import ../examples/webapps-sysvinit/processes.nix {
    forceDisableUserChange = true;
    stateDir = "/home/unprivileged/var";
  }).webapp.pkg;

  processesEnv = import ../nixproc/create-managed-process/sysvinit/build-sysvinit-env.nix {
    exprFile = ../examples/webapps-sysvinit/processes.nix;
  };

  processesEnvUnprivileged = import ../nixproc/create-managed-process/sysvinit/build-sysvinit-env.nix {
    exprFile = ../examples/webapps-sysvinit/processes.nix;
    forceDisableUserChange = true;
    stateDir = "/home/unprivileged/var";
  };

  processesEnvAdvanced = import ../nixproc/create-managed-process/sysvinit/build-sysvinit-env.nix {
    exprFile = ../examples/webapps-sysvinit/processes-advanced.nix;
  };

  processesEnvAdvancedUnprivileged = import ../nixproc/create-managed-process/sysvinit/build-sysvinit-env.nix {
    exprFile = ../examples/webapps-sysvinit/processes-advanced.nix;
    forceDisableUserChange = true;
    stateDir = "/home/unprivileged/var";
  };

  processesEnvEmpty = import ../nixproc/create-managed-process/sysvinit/build-sysvinit-env.nix {
    exprFile = null;
  };

  processesEnvEmptyUnprivileged = import ../nixproc/create-managed-process/sysvinit/build-sysvinit-env.nix {
    exprFile = null;
    forceDisableUserChange = true;
    stateDir = "/home/unprivileged/var";
  };

  tools = import ../tools {};

  nix-processmgmt = ./..;

  env = "NIX_PATH=nixpkgs=${nixpkgs}";
in
makeTest {
  machine =
    {pkgs, ...}:

    {
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [
        webappUnprivileged
        processesEnv
        processesEnvUnprivileged
        processesEnvAdvanced
        processesEnvAdvancedUnprivileged
        processesEnvEmpty
        processesEnvEmptyUnprivileged
      ];

      virtualisation.writableStore = true;

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
        tools.common
        tools.sysvinit
      ];
    };

  testScript = ''
    def check_webapp_daemon(package):
        machine.succeed(
            'su - unprivileged -c "{}/etc/rc.d/init.d/webapp start"'.format(package)
        )

        machine.succeed("pgrep -u unprivileged -f '/bin/webapp -D$'")
        machine.succeed("curl --fail http://localhost:5000 | grep 'Simple test webapp'")

        machine.succeed(
            'su - unprivileged -c "{}/etc/rc.d/init.d/webapp stop"'.format(package)
        )

        machine.fail("curl --fail http://localhost:5000 | grep 'Simple test webapp'")


    def check_nginx_redirection():
        machine.succeed(
            "curl --fail -H 'Host: webapp.local' http://localhost:8080 | grep 'listening on port: 5000'"
        )


    def check_nginx_multi_instance_redirection():
        machine.succeed(
            "curl --fail -H 'Host: webapp1.local' http://localhost:8080 | grep 'listening on port: 5001'"
        )
        machine.succeed(
            "curl --fail -H 'Host: webapp5.local' http://localhost:8081 | grep 'listening on port: 5005'"
        )


    def check_system_unavailable():
        machine.fail("curl --fail http://localhost:8080")
        machine.fail("pgrep -f '/bin/webapp'")


    start_all()

    # Make sure the unprivileged user can deploy (this implicitly creates all required state folders)
    machine.succeed(
        "su - unprivileged -c '${env} nixproc-sysvinit-switch --state-dir /home/unprivileged/var --force-disable-user-change --undeploy'"
    )

    # Test webapp deployed by an unprivileged user
    check_webapp_daemon("${webappUnprivileged}")

    # Deploy the entire system as an unprivileged user
    machine.succeed(
        "su - unprivileged -c '${env} nixproc-sysvinit-switch --state-dir /home/unprivileged/var --force-disable-user-change ${nix-processmgmt}/examples/webapps-sysvinit/processes.nix'"
    )

    check_nginx_redirection()

    # Upgrade to the multi-instance example and check if the redirections are done right
    machine.succeed(
        "su - unprivileged -c '${env} nixproc-sysvinit-switch --state-dir /home/unprivileged/var --force-disable-user-change ${nix-processmgmt}/examples/webapps-sysvinit/processes-advanced.nix'"
    )

    check_nginx_multi_instance_redirection()

    # Undeploy the entire system as an unprivileged user
    machine.succeed(
        "su - unprivileged -c '${env} nixproc-sysvinit-switch --state-dir /home/unprivileged/var --force-disable-user-change --undeploy'"
    )

    check_system_unavailable()

    # Deploy the entire system
    machine.succeed(
        "${env} nixproc-sysvinit-switch ${nix-processmgmt}/examples/webapps-sysvinit/processes.nix"
    )

    check_nginx_redirection()

    # Upgrade to the multi-instance example and check if the redirections are done right
    machine.succeed(
        "${env} nixproc-sysvinit-switch ${nix-processmgmt}/examples/webapps-sysvinit/processes-advanced.nix"
    )

    check_nginx_multi_instance_redirection()

    # Roll back to the previous configuration
    machine.succeed(
        "${env} nixproc-sysvinit-switch --rollback"
    )

    check_nginx_redirection()

    # Undeploy the entire system
    machine.succeed(
        "${env} nixproc-sysvinit-switch --undeploy"
    )

    check_system_unavailable()

    # Delete all generations and check if there are none left
    machine.succeed(
        "${env} nixproc-sysvinit-switch --delete-all-generations"
    )

    result = machine.succeed(
        "${env} nixproc-sysvinit-switch --list-generations | wc -l"
    )

    if int(result) > 0:
        raise Exception("We should have no profile generations")
  '';
}

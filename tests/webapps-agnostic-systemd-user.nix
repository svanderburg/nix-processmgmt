{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  processesEnvAuto = import ../nixproc/create-managed-process/systemd/build-systemd-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
    stateDir = "/home/unprivileged/var";
    forceDisableUserChange = true;
  };

  processesEnvEmpty = import ../nixproc/create-managed-process/systemd/build-systemd-env.nix {
    exprFile = ../examples/webapps-agnostic/processes-empty.nix;
    stateDir = "/home/unprivileged/var";
    forceDisableUserChange = true;
  };

  tools = import ../tools {};

  nix-processmgmt = ./..;

  env = "NIX_PATH=nixpkgs=${nixpkgs} XDG_RUNTIME_DIR=/run/user/1000";
in
makeTest {
  machine =
    {pkgs, lib, ...}:

    {
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [ processesEnvAuto processesEnvEmpty ];
      virtualisation.writableStore = true;
      virtualisation.memorySize = 1024;

      # We can't download any substitutes in a test environment. To make tests
      # faster, we disable substitutes so that Nix does not waste any time by
      # attempting to download them.
      nix.extraOptions = ''
        substitute = false
      '';

      users.extraUsers = {
        unprivileged = {
          uid = 1000;
          group = "users";
          shell = "/bin/sh";
          description = "Unprivileged user";
          home = "/home/unprivileged";
          createHome = true;
          isNormalUser = true;
        };
      };

      services.xserver = {
        enable = true;

        displayManager.lightdm = {
          enable = true;
          autoLogin = {
            enable = true;
            user = "unprivileged";
          };
        };

        # Use IceWM as the window manager.
        # Don't use a desktop manager.
        displayManager.defaultSession = lib.mkDefault "none+icewm";
        windowManager.icewm.enable = true;
      };

      # lightdm by default doesn't allow auto login for root, which is
      # required by some nixos tests. Override it here.
      security.pam.services.lightdm-autologin.text = lib.mkForce ''
        auth     requisite pam_nologin.so
        auth     required  pam_succeed_if.so quiet
        auth     required  pam_permit.so

        account  include   lightdm

        password include   lightdm

        session  include   lightdm
      '';

      environment.systemPackages = [
        pkgs.stdenv
        pkgs.dysnomia
        tools.build
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


    start_all()
    machine.wait_for_unit("display-manager.service")

    machine.succeed('su - unprivileged -c "mkdir -p /home/unprivileged/var"')

    # Deploy the entire system in auto mode. Should result in foreground webapp processes

    machine.succeed(
        'su - unprivileged -c "${env} nixproc-systemd-switch --user --state-dir /home/unprivileged/var --force-disable-user-change ${nix-processmgmt}/examples/webapps-agnostic/processes.nix"'
    )

    machine.succeed("sleep 1")
    machine.succeed("pgrep -u unprivileged -f '/bin/webapp$'")

    check_nginx_redirection()

    # Undeploy the system

    machine.succeed(
        'su - unprivileged -c "${env} nixproc-systemd-switch --user --state-dir /home/unprivileged/var --force-disable-user-change ${nix-processmgmt}/examples/webapps-agnostic/processes-empty.nix"'
    )

    check_system_unavailable()
  '';
}

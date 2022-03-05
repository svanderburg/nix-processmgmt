{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  processesEnvAuto = import ../nixproc/backends/supervisord/build-supervisord-env.nix {
    exprFile = ../examples/webapps-agnostic/processes.nix;
  };

  tools = import ../tools {};

  nix-processmgmt = ./..;

  env = "NIX_PATH=nixpkgs=${nixpkgs}";
in
makeTest {
  machine =
    {pkgs, ...}:

    {
      virtualisation.additionalPaths = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [ processesEnvAuto ];
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
        pkgs.daemon
        pkgs.pythonPackages.supervisor
        pkgs.dysnomia
        tools.common
        tools.systemd
        tools.supervisord
      ];
    };

  testScript = ''
    def check_nginx_redirection():
        machine.succeed(
            "curl --fail -H 'Host: webapp.local' http://localhost:8080 | grep 'listening on port: 5000'"
        )


    start_all()

    # Deploy the advanced example with multiple instances and see if it works

    machine.succeed(
        "${env} daemon --inherit --unsafe -- nixproc-supervisord-deploy-stateless ${nix-processmgmt}/examples/webapps-agnostic/processes.nix"
    )

    machine.wait_for_open_port(9001)
    machine.succeed("sleep 30")
    check_nginx_redirection()
  '';
}

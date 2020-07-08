{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  processesEnvAuto = import ../nixproc/create-managed-process/supervisord/build-supervisord-env.nix {
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
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [ processesEnvAuto ];
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


    start_all()

    # Deploy the advanced example with multiple instances and see if it works

    machine.succeed(
        "${env} nixproc-supervisord-deploy-stateless ${nix-processmgmt}/examples/webapps-agnostic/processes.nix &"
    )

    machine.succeed("sleep 30")
    machine.succeed("cat supervisord.log >&2")
    check_nginx_redirection()
  '';
}

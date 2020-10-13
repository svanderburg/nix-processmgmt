{nixpkgs ? <nixpkgs>}:

with import "${nixpkgs}/nixos/lib/testing-python.nix" { system = builtins.currentSystem; };

let
  webappUnprivilegedAutoModeConfig = (import ../examples/webapps-agnostic/processes.nix {
    forceDisableUserChange = true;
    processManager = null;
    webappMode = null;
  }).webapp.pkg;

  webappUnprivilegedAutoModeSysvinit = (import ../examples/webapps-agnostic/processes.nix {
    forceDisableUserChange = true;
    processManager = "sysvinit";
    webappMode = null;
  }).webapp.pkg;

  tools = import ../tools {};

  nix-processmgmt = ./..;

  env = "NIX_PATH=nixpkgs=${nixpkgs}";
in
makeTest {
  machine =
    {pkgs, ...}:

    {
      virtualisation.pathsInNixDB = [ pkgs.stdenv ] ++ pkgs.coreutils.all ++ [
        webappUnprivilegedAutoModeConfig
        webappUnprivilegedAutoModeSysvinit
      ];

      virtualisation.writableStore = true;

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
        tools.generate-config
      ];
    };

  testScript = ''
    start_all()

    # Make sure the unprivileged user can deploy
    machine.succeed("mkdir -p var/run var/tmp")

    result = machine.succeed(
        "cat ${webappUnprivilegedAutoModeConfig}/webapp.json >&2"
    )

    result = machine.succeed(
        "${env} nixproc-generate-config --process-manager sysvinit --force-disable-user-change ${webappUnprivilegedAutoModeConfig}/webapp.json"
    )

    machine.succeed("{}/etc/rc.d/init.d/webapp start".format(result[:-1]))
    machine.succeed("pgrep -f '/bin/webapp -D$'")
    machine.succeed("curl --fail http://localhost:5000 | grep 'Simple test webapp'")
  '';
}

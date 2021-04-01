{ pkgs, testService, processManagers, profiles }:

let
  generateTestExecutable = instanceName:
    pkgs.writeTextFile {
      name = "test-${instanceName}";
      text = ''
        #! ${pkgs.stdenv.shell} -e

        while true
        do
            echo "Hello ${instanceName}!" >&2
            sleep 1
        done
      '';
      executable = true;
    };

  generateTestConfigDir = instanceName:
    pkgs.stdenv.mkDerivation {
      name = "sv";
      buildCommand = ''
        mkdir -p $out/test-${instanceName}
        cd $out/test-${instanceName}

        # Generate longrun service for test process
        echo "longrun" > type
        cat > run <<EOF
        #!${pkgs.execline}/bin/execlineb -P
        exec ${generateTestExecutable instanceName}
        EOF

        # Generate default bundle containing the above service
        mkdir -p ../default
        cd ../default
        echo "bundle" > type
        cat > contents <<EOF
        test-${instanceName}
        EOF
      '';
    };
in
testService {
  exprFile = ./processes.nix;
  systemPackages = [ pkgs.s6-rc ];

  readiness = {instanceName, instance, runtimeDir, ...}:
    ''
      machine.wait_for_file("${runtimeDir}/service${instance.instanceSuffix}/.s6-svscan")
    '';

  tests = {instanceName, instance, stateDir, runtimeDir, forceDisableUserChange, ...}:
    let
      liveDir = "${stateDir}/run/s6-rc${instance.instanceSuffix}";
      compileDir = "${stateDir}/etc/s6${instance.instanceSuffix}/rc";
      compiledDatabasePath = "${compileDir}/compiled";
    in
    ''
      # fmt: off
      machine.succeed(
          "${pkgs.lib.optionalString forceDisableUserChange "su unprivileged -c '"}mkdir -p ${compileDir}${pkgs.lib.optionalString forceDisableUserChange "'"}"
      )
      machine.succeed(
          "${pkgs.lib.optionalString forceDisableUserChange "su unprivileged -c '"}s6-rc-compile ${compiledDatabasePath} ${generateTestConfigDir instanceName}${pkgs.lib.optionalString forceDisableUserChange "'"}"
      )
      machine.succeed(
          "${pkgs.lib.optionalString forceDisableUserChange "su unprivileged -c '"}s6-rc-init -c ${compiledDatabasePath} -l ${liveDir} ${runtimeDir}/service${instance.instanceSuffix}${pkgs.lib.optionalString forceDisableUserChange "'"}"
      )
      machine.succeed(
          "${pkgs.lib.optionalString forceDisableUserChange "su unprivileged -c '"}s6-rc -l ${liveDir} -u change default${pkgs.lib.optionalString forceDisableUserChange "'"}"
      )
      # fmt: on

      machine.succeed("sleep 1")
      machine.succeed(
          "pgrep -f '${generateTestExecutable instanceName}'"
      )
    '';

  inherit processManagers profiles;
}

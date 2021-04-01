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

  generateTestConf = instanceName:
    pkgs.writeTextFile {
      name = "test-${instanceName}.conf";
      text = ''
        [program:test-${instanceName}]
        command=${generateTestExecutable instanceName}
      '';
    };
in
testService {
  exprFile = ./processes.nix;
  systemPackages = [ pkgs.pythonPackages.supervisor ];

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, stateDir, ...}:
    ''
      machine.succeed(
          "cp ${generateTestConf instanceName} ${stateDir}/lib/${instanceName}/conf.d"
      )
      machine.succeed("supervisorctl --serverurl http://localhost:${toString instance.port} reread")
      machine.succeed("supervisorctl --serverurl http://localhost:${toString instance.port} update")
      machine.succeed("sleep 1")
      machine.succeed(
          "pgrep -f '${generateTestExecutable instanceName}'"
      )
    '';

  inherit processManagers profiles;
}

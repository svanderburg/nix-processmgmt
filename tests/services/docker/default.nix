{ pkgs, testService, processManagers, profiles }:

testService {
  exprFile = ./processes.nix;
  systemPackages = [ pkgs.docker ];

  readiness = {instanceName, instance, runtimeDir, ...}:
    ''
      machine.wait_for_file("${runtimeDir}/${instanceName}.sock")
    '';

  tests = {instanceName, instance, stateDir, runtimeDir, forceDisableUserChange, ...}:
    # The primary instance should be connectible with the default parameters
    if instanceName == "docker" && !forceDisableUserChange then ''
      machine.succeed("docker info | grep 'Docker Root Dir: ${stateDir}/lib/${instanceName}'")
    '' else ''
      machine.succeed(
          "docker --host=unix://${runtimeDir}/${instanceName}.sock info | grep 'Docker Root Dir: ${stateDir}/lib/${instanceName}'"
      )
    '';

  inherit processManagers;

  # There's an experimental rootless feature for Docker, but a hassle to setup. As a result, we disable unprivileged mode
  profiles = builtins.filter (profile: profile == "privileged") profiles;
}

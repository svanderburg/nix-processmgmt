{
  test1 = {pkgs, ...}:
  {
    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.memorySize = 4096; # megabytes
  };

  test2 = {pkgs, ...}:
  {
    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.memorySize = 4096; # megabytes
  };

}

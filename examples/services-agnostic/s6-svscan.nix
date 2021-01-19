{createManagedProcess, s6, runtimeDir}:
{instanceSuffix ? "", instanceName ? "s6-svscan${instanceSuffix}", scanDir ? "${runtimeDir}/service${instanceSuffix}"}:

createManagedProcess {
  name = instanceName;
  path = [ s6 ];
  foregroundProcess = "${s6}/bin/s6-svscan";
  args = [ scanDir ];
  initialize = ''
    mkdir -p ${scanDir}
  '';
}

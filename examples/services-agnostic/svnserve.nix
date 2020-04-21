{createManagedProcess, stdenv, subversion, runtimeDir, forceDisableUserChange}:
{instanceSuffix ? "", port ? 3690, svnBaseDir, svnGroup, postInstall ? ""}:

let
  instanceName = "svnserve${instanceSuffix}";
  pidFile = "${runtimeDir}/${instanceName}.pid";
in
createManagedProcess {
  name = instanceName;
  inherit instanceName postInstall;
  initialize = ''
    mkdir -p ${svnBaseDir}
    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chgrp ${svnGroup} ${svnBaseDir}
    ''}
  '';
  process = "${subversion.out}/bin/svnserve";
  args = [ "-r" svnBaseDir "--listen-port" (toString port) ];
  foregroundProcessExtraArgs = [ "--foreground" ];
  daemonExtraArgs = [ "--daemon" "--pid-file" pidFile ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

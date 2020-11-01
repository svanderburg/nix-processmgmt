{dockerTools, commonTools, stdenv, dysnomia, findutils, glibc, stateDir, runtimeDir, forceDisableUserChange, credentialsSpec}:

''
  ${dockerTools.shadowSetup}

  # Always create these global state directories, because they are needed quite often
  mkdir -p /run /tmp
  chmod 1777 /tmp

  # Initialize common state directories
  ${commonTools}/bin/nixproc-init-state --state-dir ${stateDir} --runtime-dir ${runtimeDir}

  ${stdenv.lib.optionalString (!forceDisableUserChange && credentialsSpec != null) ''
    export PATH=$PATH:${findutils}/bin:${glibc.bin}/bin
    ${dysnomia}/bin/dysnomia-addgroups ${credentialsSpec}
    ${dysnomia}/bin/dysnomia-addusers ${credentialsSpec}
  ''}

  ${stdenv.lib.optionalString forceDisableUserChange ''
    groupadd -r nogroup
    useradd -r nobody -g nogroup -d /dev/null
  ''}
''

{createManagedProcess, writeTextFile, openssh, stateDir, runtimeDir, tmpDir, forceDisableUserChange}:
{instanceSuffix ? "", instanceName ? "sshd${instanceSuffix}", port ? 22, extraSSHDConfig ? ""}:

let
  sshdStateDir = "${stateDir}/lib/${instanceName}";

  sshdConfig = writeTextFile {
    name = "sshd_config";
    text = ''
      HostKey ${sshdStateDir}/ssh_host_rsa_key
      HostKey ${sshdStateDir}/ssh_host_ecdsa_key
      HostKey ${sshdStateDir}/ssh_host_ed25519_key

      PidFile ${if forceDisableUserChange then tmpDir else runtimeDir}/${instanceName}.pid
      ${extraSSHDConfig}
    '';
  };

  group = instanceName;
  user = instanceName;
in
createManagedProcess {
  name = instanceName;
  inherit instanceName;

  initialize = ''
    mkdir -p ${sshdStateDir}
    mkdir -p /var/empty

    if [ ! -f ${sshdStateDir}/ssh_host_rsa_key ]
    then
        ssh-keygen -t rsa -f ${sshdStateDir}/ssh_host_rsa_key -N ""
    fi

    if [ ! -f ${sshdStateDir}/ssh_host_ecdsa_key ]
    then
        ssh-keygen -t ecdsa -f ${sshdStateDir}/ssh_host_ecdsa_key -N ""
    fi

    if [ ! -f ${sshdStateDir}/ssh_host_ed25519_key ]
    then
        ssh-keygen -t ed25519 -f ${sshdStateDir}/ssh_host_ed25519_key -N ""
    fi
  '';

  process = "${openssh}/bin/sshd";
  args = [ "-p" port "-f" sshdConfig ];
  foregroundProcessExtraArgs = [ "-D" ];
  path = [ openssh ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        homeDir = "/var/empty";
        description = "SSH privilege separation user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

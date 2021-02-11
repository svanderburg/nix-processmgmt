{pkgs, common, input, result}:

result // {
  runAsRoot = result.runAsRoot or "" + ''
    ${pkgs.dockerTools.shadowSetup}

    # Always create these global state directories, because they are needed quite often
    mkdir -p /run /tmp
    chmod 1777 /tmp

    mkdir -p /var/empty
    ln -s ../run /var/run

    # Always create nobody/nogroup
    groupadd -g 65534 -r nogroup
    useradd -u 65534 -r nobody -g nogroup -d /dev/null
  '';
}

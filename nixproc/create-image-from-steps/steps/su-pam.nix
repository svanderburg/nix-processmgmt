{pkgs, common, input, result}:

result // {
  runAsRoot = result.runAsRoot or "" + ''
    mkdir -p /etc/pam.d
    cat > /etc/pam.d/su <<EOF
    account required pam_unix.so
    auth sufficient pam_rootok.so
    auth required pam_tally.so
    auth sufficient pam_unix.so likeauth try_first_pass
    auth required pam_deny.so
    password sufficient pam_unix.so nullok sha512
    EOF

    sed -i -e "s|PATH=/bin:/usr/bin|PATH=/bin:/usr/bin:/nix/var/nix/profiles/default/bin|" /etc/login.defs

    cat > /etc/nsswitch.conf <<EOF
    passwd:    files
    group:     files [success=merge]
    shadow:    files

    hosts:     mymachines files myhostname dns
    networks:  files

    ethers:    files
    services:  files
    protocols: files
    rpc:       files
    EOF
  '';

  contents = result.contents or [] ++ [ pkgs.su pkgs.shadow ];
}

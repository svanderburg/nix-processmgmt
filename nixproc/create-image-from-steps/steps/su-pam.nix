{pkgs, common, input, result}:

result // {
  runAsRoot = result.runAsRoot or "" + ''
    ${pkgs.gnused}/bin/sed -i -e "s/CREATE_MAIL_SPOOL=yes/CREATE_MAIL_SPOOL=no/" /etc/default/useradd

    mkdir -p /etc/pam.d
    cat > /etc/pam.d/su <<EOF
    account required pam_unix.so
    auth sufficient pam_rootok.so
    auth required pam_tally.so
    auth sufficient pam_unix.so likeauth try_first_pass
    auth required pam_deny.so
    password sufficient pam_unix.so nullok sha512
    EOF
  '';

  contents = result.contents or [] ++ [ pkgs.su pkgs.shadow ];
}

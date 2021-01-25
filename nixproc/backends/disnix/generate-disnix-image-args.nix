{pkgs, system, exprFile, stateDir, runtimeDir, forceDisableUserChange, extraParams}:

let
  sysvinitTools = (import ../../../tools {
    inherit pkgs system;
  }).sysvinit;

  generateCompoundProxy = import ../util/generate-compound-proxy.nix {
    inherit (pkgs) stdenv writeTextFile;
  };

  disnixDataDir = "${pkgs.disnix}/share/disnix";

  profile = import ./build-disnix-env.nix {
    inherit pkgs system exprFile stateDir runtimeDir forceDisableUserChange extraParams disnixDataDir;
  };

  emptyProfile = import ./build-disnix-env.nix {
    inherit pkgs system stateDir runtimeDir forceDisableUserChange extraParams disnixDataDir;
    exprFile = null;
  };

  script = generateCompoundProxy {
    path = [ pkgs.dysnomia pkgs.disnix ];
    startCommand = "disnix-activate ${profile}";
    stopCommand = "disnix-activate -o ${profile} ${emptyProfile}";
  };
in
{
  runAsRoot = pkgs.lib.optionalString (!forceDisableUserChange) ''
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
  contents = [ pkgs.shadow pkgs.su pkgs.disnix pkgs.dysnomia ];
  cmd = [ script ];
  credentialsSpec = null;
}

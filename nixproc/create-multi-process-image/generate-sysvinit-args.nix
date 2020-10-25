{pkgs, system, exprFile, stateDir, runtimeDir, forceDisableUserChange, extraParams}:

let
  sysvinitTools = (import ../../tools {
    inherit pkgs system;
  }).sysvinit;

  generateCompoundProxy = import ./generate-compound-proxy.nix {
    inherit (pkgs) stdenv writeTextFile;
  };

  runlevel = "3";

  script = generateCompoundProxy {
    startCommand = "${sysvinitTools}/bin/nixproc-sysvinit-runactivity start ${profile}";
    stopCommand = "${sysvinitTools}/bin/nixproc-sysvinit-runactivity -r stop ${profile}";
  };

  profile = import ../create-managed-process/sysvinit/build-sysvinit-env.nix {
    inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams;
  };
in
{
  runAsRoot = ''
    ln -s ${profile}/etc/rc.d /etc/rc.d
  '';
  contents = [ pkgs.su pkgs.sysvinit pkgs.gnugrep pkgs.coreutils ];
  cmd = [ script ];
  credentialsSpec = profile;
}

{pkgs, common, input, result}:

let
  sysvinitTools = (import ../../../../tools {
    inherit pkgs;
    inherit (common) system;
  }).sysvinit;

  generateCompoundProxy = import ../../util/generate-compound-proxy.nix {
    inherit (pkgs) stdenv writeTextFile;
  };

  runlevel = "3";

  script = generateCompoundProxy {
    startCommand = "${sysvinitTools}/bin/nixproc-sysvinit-runactivity --runlevel ${runlevel} start /";
    stopCommand = "${sysvinitTools}/bin/nixproc-sysvinit-runactivity --runlevel ${runlevel} -r stop /";
  };
in
result // {
  runAsRoot = result.runAsRoot or "" + ''
    # Make symlink to processes profile
    ln -s /nix/var/nix/profiles/processes/etc/rc.d /etc/rc.d
  '';
  config = result.config or {} // {
    Cmd = [ script ];
  };
  contents = result.contents or [] ++ [ sysvinitTools ];
}

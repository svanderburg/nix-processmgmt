{pkgs, common, input, result}:

let
  sysvinitTools = (import ../../../../tools {
    inherit pkgs;
    inherit (common) system;
  }).sysvinit;

  generateCompoundProxy = import ../../util/generate-compound-proxy.nix {
    inherit (pkgs) stdenv lib writeTextFile;
  };

  runlevel = "3";

  script = generateCompoundProxy {
    startCommand = "${sysvinitTools}/bin/nixproc-sysvinit-runactivity start ${profile}";
    stopCommand = "${sysvinitTools}/bin/nixproc-sysvinit-runactivity -r stop ${profile}";
  };

  profile = import ../build-sysvinit-env.nix {
    inherit (input) exprFile stateDir runtimeDir forceDisableUserChange extraParams;
  };
in
result // {
  runAsRoot = result.runAsRoot or "" + ''
    ln -s ${profile}/etc/rc.d /etc/rc.d

    ${pkgs.lib.optionalString (!input.forceDisableUserChange) ''
      export PATH=$PATH:${pkgs.findutils}/bin:${pkgs.glibc.bin}/bin
      ${pkgs.dysnomia}/bin/dysnomia-addgroups ${profile}
      ${pkgs.dysnomia}/bin/dysnomia-addusers ${profile}
    ''}
  '';
  config = result.config or {} // {
    Cmd = [ script ];
  };
}

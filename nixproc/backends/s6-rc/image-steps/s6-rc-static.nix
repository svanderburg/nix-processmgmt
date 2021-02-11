{pkgs, common, input, result}:

let
  profile = import ../build-s6-rc-env.nix {
    inherit pkgs;
    inherit (common) system;
    inherit (input) exprFile extraParams stateDir runtimeDir forceDisableUserChange;
  };
in
result // {
  runAsRoot = result.runAsRoot or "" + ''
    # Initialize s6-rc with a compiled database
    mkdir -p /etc/s6/rc
    s6-rc-compile /etc/s6/rc/compiled ${profile}/etc/s6/sv

    ${pkgs.lib.optionalString (!input.forceDisableUserChange) ''
      export PATH=$PATH:${pkgs.findutils}/bin:${pkgs.glibc.bin}/bin
      ${pkgs.dysnomia}/bin/dysnomia-addgroups ${profile}
      ${pkgs.dysnomia}/bin/dysnomia-addusers ${profile}
    ''}
  '';
}

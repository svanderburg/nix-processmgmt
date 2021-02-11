{pkgs, common, input, result}:

let
  profile = import ../build-supervisord-env.nix {
    inherit pkgs;
    inherit (input) exprFile extraParams stateDir runtimeDir forceDisableUserChange;
    inherit (common) system;
  };
in
result // {
  runAsRoot = result.runAsRoot or "" + ''
    ln -s ${profile} /etc/supervisor

    ${pkgs.lib.optionalString (!input.forceDisableUserChange) ''
      export PATH=$PATH:${pkgs.findutils}/bin:${pkgs.glibc.bin}/bin
      ${pkgs.dysnomia}/bin/dysnomia-addgroups ${profile}
      ${pkgs.dysnomia}/bin/dysnomia-addusers ${profile}
    ''}
  '';
}

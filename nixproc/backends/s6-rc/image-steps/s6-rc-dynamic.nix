{pkgs, common, input, result}:

let
  s6-rcTools = (import ../../../../tools {
    inherit pkgs;
    inherit (common) system;
  }).s6-rc;
in
result // {
  runAsRoot = result.runAsRoot or "" + ''
    # Create empty service directory
    mkdir -p /etc/s6/sv

    # Initialize s6-rc with a compiled database
    mkdir -p /etc/s6/rc
    s6-rc-compile /etc/s6/rc/compiled /etc/s6/sv
  '';
  contents = result.contents or [] ++ [ s6-rcTools ];
}

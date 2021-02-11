{pkgs, common, input, result}:

let
  commonTools = (import ../../../tools {
    inherit pkgs;
    inherit (common) system;
  }).common;
in
result // {
  runAsRoot = result.runAsRoot or "" + ''
    # Initialize common state directories
    ${commonTools}/bin/nixproc-init-state --state-dir ${input.stateDir} --runtime-dir ${input.runtimeDir}
  '';
}

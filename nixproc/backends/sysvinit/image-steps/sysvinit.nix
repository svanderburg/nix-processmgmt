{pkgs, common, input, result}:

result // {
  contents = result.contents or [] ++ [ pkgs.sysvinit pkgs.gnugrep pkgs.coreutils ];
}

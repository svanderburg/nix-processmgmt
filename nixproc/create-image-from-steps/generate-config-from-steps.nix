{pkgs, common ? {}, input, steps}:

pkgs.lib.foldl (result: moduleFile:
  import moduleFile {
    inherit pkgs common input result;
  }
) {} steps

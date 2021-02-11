{pkgs, common, input, result}:

let
  buildImageFormalArgs = builtins.functionArgs pkgs.dockerTools.buildImage;
  buildImageArgs = builtins.intersectAttrs buildImageFormalArgs input;
in
buildImageArgs

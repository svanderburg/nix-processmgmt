{stdenv}:
{name, ...}@properties:

let
  configJSON = builtins.toJSON properties;
in
stdenv.mkDerivation {
  inherit name configJSON;
  passAsFile = [ "configJSON" ];
  buildCommand = ''
    mkdir -p $out
    cp $configJSONPath $out/${name}.json
  '';
}

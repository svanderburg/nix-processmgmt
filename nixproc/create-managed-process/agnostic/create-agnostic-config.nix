{stdenv}:
properties:

let
  configJSON = builtins.toJSON properties;
in
stdenv.mkDerivation rec {
  name = if properties ? name then properties.name else properties.instanceName;
  inherit configJSON;
  passAsFile = [ "configJSON" ];
  buildCommand = ''
    mkdir -p $out
    cp $configJSONPath $out/${name}.json
  '';
}

{stdenv, lib}:

{ name
, dockerImage
, dockerImageTag
, dockerCreateParameters ? []
, useHostNixStore ? false
, useHostNetwork ? false
, mapStateDirVolumes ? []
, cmd ? ""
, environment ? {}
, storePaths ? []
, dependencies ? []
, postInstall ? ""
}:

let
  dockerCreateParametersList =
    if builtins.isList dockerCreateParameters then dockerCreateParameters
    else if builtins.isAttrs dockerCreateParameters then map (name: { inherit name; value = builtins.getAttr name dockerCreateParameters; }) (builtins.attrNames dockerCreateParameters)
    else throw "Unknown type for the dockerCreateParameters";

  _dockerCreateParameters = dockerCreateParametersList
    ++ lib.optional useHostNixStore { name = "volume"; value = "/nix/store:/nix/store"; }
    ++ lib.optional useHostNetwork { name = "network"; value = "host"; }
    ++ map (mapStateDirVolume: { name = "volume"; value = "${mapStateDirVolume}:${mapStateDirVolume}:z"; }) mapStateDirVolumes;

  priority = if dependencies == [] then 1
    else builtins.head (builtins.sort (a: b: a > b) (map (dependency: dependency.priority) dependencies)) + 1;

  sequenceNumberToString = number:
    if number < 10 then "0${toString number}"
    else toString number;
in
stdenv.mkDerivation {
  inherit name priority;
  buildCommand = ''
    mkdir -p $out

    cat > $out/${name}-docker-settings <<EOF
    dockerImage=${dockerImage}
    dockerImageTag=${name}:latest
    EOF

    cat > $out/${name}-docker-createparams <<EOF
    ${lib.concatMapStringsSep "\n" (nameValuePair:
      "${if builtins.stringLength nameValuePair.name > 1 then "--" else "-"}${nameValuePair.name}"
      + (if nameValuePair ? value then "\n${toString nameValuePair.value}" else "")
    ) _dockerCreateParameters}
    EOF

    touch $out/${sequenceNumberToString priority}-${name}-docker-priority

    ${lib.optionalString useHostNixStore ''
      # Add configuration files with Nix store paths used from the host system so that they will not be garbage collected
      ${lib.optionalString (cmd != "") ''
        cat > $out/${name}-docker-cmd <<EOF
        ${toString cmd}
        EOF
      ''}

      ${lib.optionalString (storePaths != []) ''
        cat > $out/${name}-storepaths <<EOF
        ${lib.concatMapStrings (storePath: "${storePath}\n") storePaths}
        EOF
      ''}
    ''}
    ${postInstall}
  '';
}

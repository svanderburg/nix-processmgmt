{stdenv, createCredentials, forceDisableUserChange}:

{ name
, process
, pidFile ? null
, dependencies ? []
, postInstall ? ""
, credentials ? {}
}:

let
  credentialsSpec = credentialsSpec = util.createCredentialsOrNull {
    inherit createCredentials credentials forceDisableUserChange;
  };
in
stdenv.mkDerivation {
  inherit name;
  buildCommand = ''
    mkdir -p $out/etc/dysnomia/process
    cat > $out/etc/dysnomia/process/${name} <<EOF
    process=${process}
    ${stdenv.lib.optionalString (pidFile != null) "pidFile=${pidFile}"}
    EOF

    ${stdenv.lib.optionalString (credentialsSpec != null) ''
      ln -s ${credentialsSpec}/dysnomia-support $out/dysnomia-support
    ''}

    ${postInstall}
  '';
  passthru = {
    inherit dependencies;
  };
}

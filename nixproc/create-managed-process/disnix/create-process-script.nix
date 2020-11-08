{stdenv, createCredentials, forceDisableUserChange}:

{ name
, process
, pidFile ? null
, dependencies ? []
, postInstall ? ""
, credentials ? {}
}:

let
  credentialsSpec = createCredentials credentials;
in
stdenv.mkDerivation {
  inherit name;
  buildCommand = ''
    mkdir -p $out/etc/dysnomia/process
    cat > $out/etc/dysnomia/process/${name} <<EOF
    process=${process}
    ${stdenv.lib.optionalString (pidFile != null) "pidFile=${pidFile}"}
    EOF

    ln -s ${credentialsSpec}/dysnomia-support $out/dysnomia-support

    ${postInstall}
  '';
  passthru = {
    inherit dependencies;
  };
}

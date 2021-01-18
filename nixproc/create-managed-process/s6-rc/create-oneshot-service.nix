{stdenv, createCredentials}:

{ name
# When a service is flagged as essential it will not stop with the command: s6-rc -d change foo, but only: s6-rc -D change foo
, flagEssential ? false
# Script to run when the service is brought up (typically an execline script, but this is not mandatory)
, up
# Script to run when the service is brought down (typically an execline script, but this is not mandatory). null disables the script.
, down ? null
# A list of dependencies on other s6-rc services
, dependencies ? []
# Specifies which groups and users that need to be created.
, credentials ? {}
# Arbitrary commands executed after generating the configuration files
, postInstall ? ""
}:

let
  credentialsSpec = createCredentials credentials;

  util = import ./util.nix {
    inherit (stdenv) lib;
  };
in
stdenv.mkDerivation {
  inherit name;
  buildCommand = ''
    mkdir -p $out/etc/s6/sv/${name}
    cd $out/etc/s6/sv/${name}
  ''
  + util.generateStringProperty { value = "oneshot"; filename = "type"; }
  + util.generateBooleanProperty { value = flagEssential; filename = "flag-essential"; }
  + util.copyFile { path = up; filename = "up"; }
  + util.copyFile { path = down; filename = "down"; }
  + util.generateServiceNameList { services = dependencies; filename = "dependencies"; }
  + ''
    ln -s ${credentialsSpec}/dysnomia-support $out/dysnomia-support

    cd $TMPDIR
    ${postInstall}
  '';
}

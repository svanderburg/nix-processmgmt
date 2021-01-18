{stdenv}:

{ name
# When a service is flagged as essential it will not stop with the command: s6-rc -d change foo, but only: s6-rc -D change foo
, flagEssential ? false
# List of s6-rc services that are in the bundle
, contents ? []
# Arbitrary commands executed after generating the configuration files
, postInstall ? ""
}:

let
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
  + util.generateStringProperty { value = "bundle"; filename = "type"; }
  + util.generateBooleanProperty { value = flagEssential; filename = "flag-essential"; }
  + util.generateServiceNameList { services = contents; filename = "contents"; }
  + postInstall;
}

{ pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, tmpDir
, forceDisableUserChange
, processManager
, ids ? {}
}:

let
  constructors = import ../services-agnostic/constructors.nix {
    inherit pkgs stateDir logDir runtimeDir cacheDir tmpDir forceDisableUserChange processManager ids;
  };
in
{
  extendableSupervisord = import ./extendable-supervisord.nix {
    inherit stateDir;
    inherit (pkgs) stdenv;
    supervisordConstructorFun = constructors.extendableSupervisord;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableSupervisordProgram = true;
    });
  };
}

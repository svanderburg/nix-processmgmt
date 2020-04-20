{supervisordConstructorFun, stdenv, dysnomia, stateDir}:
{instanceSuffix ? "", inetHTTPServerPort ? 9001, postInstall ? "", type}:

let
  instanceName = "supervisord${instanceSuffix}";

  supervisordTargetDir = "${stateDir}/lib/${instanceName}/conf.d";

  pkg = supervisordConstructorFun {
    inherit instanceSuffix inetHTTPServerPort;
    postInstall = ''
      # Add Dysnomia container configuration file for Supervisord
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/supervisord-program${instanceSuffix} <<EOF
      supervisordTargetDir="${supervisordTargetDir}"
      EOF

      # Copy the Dysnomia module that manages a Supervisord program
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/supervisord-program $out/libexec/dysnomia
    '';
  };
in
{
  name = "supervisord${instanceSuffix}";
  inherit pkg type supervisordTargetDir;
  providesContainer = "supervisord-program";
}

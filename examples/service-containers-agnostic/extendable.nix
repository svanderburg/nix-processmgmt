{supervisordConstructorFun, stdenv, dysnomia, libDir}:

{ instanceSuffix ? "", instanceName ? "supervisord${instanceSuffix}"
, containerName ? "supervisord-program${instanceSuffix}"
, inetHTTPServerPort ? 9001
, postInstall ? ""
, type
, properties ? {}
}:

let
  supervisordTargetDir = "${libDir}/${instanceName}/conf.d";

  pkg = supervisordConstructorFun {
    inherit instanceName inetHTTPServerPort;
    postInstall = ''
      # Add Dysnomia container configuration file for Supervisord
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      supervisordTargetDir="${supervisordTargetDir}"
      EOF

      # Copy the Dysnomia module that manages a Supervisord program
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/supervisord-program $out/libexec/dysnomia
    '';
  };
in
{
  name = instanceName;
  inherit pkg type supervisordTargetDir;
  providesContainer = containerName;
} // properties

{svnserveConstructorFun, dysnomia}:
{instanceSuffix ? "", port ? 3690, svnBaseDir, svnGroup ? "root", type}:

let
  instanceName = "svnserve${instanceSuffix}";

  pkg = svnserveConstructorFun {
    inherit instanceSuffix port svnBaseDir svnGroup;
    postInstall = ''
      # Add Dysnomia container configuration file for Subversion repositories
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/subversion-repository${instanceSuffix} <<EOF
      svnGroup=${svnGroup}
      svnBaseDir=${svnBaseDir}
      EOF

      # Copy the Dysnomia module that manages a Subversion repository
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/subversion-repository $out/libexec/dysnomia
    '';
  };
in
{
  name = instanceName;
  inherit pkg type svnGroup svnBaseDir;
  providesContainer = "subversion-repository";
}

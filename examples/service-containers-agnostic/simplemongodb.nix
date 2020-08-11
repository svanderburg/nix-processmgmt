{mongodbConstructorFun, stdenv, dysnomia}:
{instanceSuffix ? "", instanceName ? "mongodb${instanceSuffix}", containerName ? "mongo-database${instanceSuffix}", bindIP ? "127.0.0.1", port ? 27017, mongoDumpArgs ? null, mongoRestoreArgs ? null, type}:

let
  pkg = mongodbConstructorFun {
    inherit instanceName bindIP port;
    postInstall = ''
      # Add Dysnomia container configuration file for MongoDB
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      ${stdenv.lib.optionalString (mongoDumpArgs != null) (toString mongoDumpArgs)}"}
      ${stdenv.lib.optionalString (mongoRestoreArgs != null) (toString mongoRestoreArgs)}"}
      EOF

      # Copy the Dysnomia module that manages a Mongo database
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/mongo-database $out/libexec/dysnomia
    '';
  };
in
{
  name = instanceName;
  inherit pkg type bindIP port;

  providesContainer = containerName;
} // (if mongoDumpArgs == null then {} else {
  inherit mongoDumpArgs;
}) // (if mongoRestoreArgs == null then {} else {
  inherit mongoRestoreArgs;
})

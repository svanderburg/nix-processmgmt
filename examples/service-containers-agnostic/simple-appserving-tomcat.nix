{tomcatConstructorFun, dysnomia, stateDir}:
{instanceSuffix ? "", serverPort ? 8005, httpPort ? 8080, httpsPort ? 8443, ajpPort ? 8009, commonLibs ? [], type}:

let
  catalinaBaseDir = "${stateDir}/tomcat${instanceSuffix}";

  pkg = tomcatConstructorFun {
    inherit instanceSuffix serverPort httpPort httpsPort ajpPort commonLibs;

    postInstall = ''
      # Add Dysnomia container configuration file for a Tomcat web application
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/tomcat-webapplication${instanceSuffix} <<EOF
      tomcatPort=${toString httpPort}
      catalinaBaseDir=${catalinaBaseDir}
      EOF

      # Copy the Dysnomia module that manages MySQL database
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/tomcat-webapplication $out/libexec/dysnomia
    '';
  };
in
rec {
  name = "simpleAppservingTomcat${instanceSuffix}";

  inherit pkg type catalinaBaseDir;
  tomcatPort = httpPort;

  providesContainer = "tomcat-webapplication${instanceSuffix}";
}

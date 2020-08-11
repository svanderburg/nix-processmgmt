{tomcatConstructorFun, dysnomia, stateDir}:
{instanceSuffix ? "", instanceName ? "tomcat${instanceSuffix}", containerName ? "tomcat-webapplication${instanceSuffix}", serverPort ? 8005, httpPort ? 8080, httpsPort ? 8443, ajpPort ? 8009, commonLibs ? [], type}:

let
  catalinaBaseDir = "${stateDir}/${instanceName}";

  pkg = tomcatConstructorFun {
    inherit instanceName serverPort httpPort httpsPort ajpPort commonLibs;

    postInstall = ''
      # Add Dysnomia container configuration file for a Tomcat web application
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
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
  name = instanceName;

  inherit pkg type catalinaBaseDir;
  tomcatPort = httpPort;

  providesContainer = containerName;
}

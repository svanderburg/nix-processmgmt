{createManagedProcess, stdenv, tomcat, jre, stateDir, runtimeDir, tmpDir, forceDisableUserChange}:
{instanceSuffix ? "", serverPort ? 8005, httpPort ? 8080, httpsPort ? 8443, ajpPort ? 8009}:

let
  tomcatConfigFiles = stdenv.mkDerivation {
    name = "tomcat-config-files";
    buildCommand = ''
      mkdir -p $out
      cd $out

      mkdir conf
      cp ${tomcat}/conf/* conf
      sed -i \
        -e 's|<Server port="8005" shutdown="SHUTDOWN">|<Server port="${toString serverPort}" shutdown="SHUTDOWN">|' \
        -e 's|<Connector port="8080" protocol="HTTP/1.1"|<Connector port="${toString httpPort}" protocol="HTTP/1.1"|' \
        -e 's|redirectPort="8443"|redirectPort="${toString httpsPort}"|' \
        -e 's|<Connector port="8009" protocol="AJP/1.3"|<Connector port="${toString ajpPort}" protocol="AJP/1.3"|' \
        conf/server.xml

      mkdir webapps
      cp -av ${tomcat.webapps}/webapps/* webapps
    '';
  };
in
import ./tomcat.nix {
  inherit createManagedProcess stdenv tomcat jre stateDir runtimeDir tmpDir forceDisableUserChange;
} {
  inherit tomcatConfigFiles instanceSuffix;
}

{createManagedProcess, stdenv, writeTextFile, nginx, runtimeDir, stateDir, cacheDir, forceDisableUserChange}:
{port ? 80, webapps ? [], instanceSuffix ? "", instanceName ? "nginx${instanceSuffix}"}:
interDependencies:

let
  user = instanceName;
  group = instanceName;

  nginxStateDir = "${stateDir}/${instanceName}";
  nginxLogDir = "${nginxStateDir}/logs";
in
import ./nginx.nix {
  inherit createManagedProcess stdenv nginx stateDir forceDisableUserChange runtimeDir cacheDir;
} {
  inherit instanceName;

  dependencies = map (webapp: webapp.pkg) webapps
    ++ map (interDependency: interDependency.pkgs."${stdenv.system}") (builtins.attrValues interDependencies);

  configFile = writeTextFile {
    name = "nginx.conf";
    text = ''
      error_log ${nginxLogDir}/error.log;

      ${stdenv.lib.optionalString (!forceDisableUserChange) ''
        user ${user} ${group};
      ''}

      events {
        worker_connections 190000;
      }

      http {
        ${stdenv.lib.concatMapStrings (dependency: ''
          upstream webapp${toString dependency.port} {
            server localhost:${toString dependency.port};
          }
        '') webapps}

        ${stdenv.lib.concatMapStrings (paramName:
          let
            dependency = builtins.getAttr paramName interDependencies;
          in
          ''
            upstream webapp${toString dependency.port} {
              server ${dependency.target.properties.hostname}:${toString dependency.port};
            }
          '') (builtins.attrNames interDependencies)}

        # Fallback virtual host displaying an error page. This is what users see
        # if they connect to a non-deployed web application.
        # Without it, nginx redirects to the first available virtual host, giving
        # unpredictable results. This could happen while an upgrade is in progress.

        server {
          listen ${toString port};
          server_name aaaa;
          root ${./errorpage};
        }

        ${stdenv.lib.concatMapStrings (dependency: ''
          server {
            listen ${toString port};
            server_name ${dependency.dnsName};

            location / {
              proxy_pass  http://webapp${toString dependency.port};
            }
          }
        '') (webapps ++ builtins.attrValues interDependencies)}
      }
    '';
  };
}

{createManagedProcess, stdenv, writeTextFile, nginx, runtimeDir, stateDir, cacheDir, forceDisableUserChange}:
{port ? 80, webapps ? [], instanceSuffix ? ""}:
interDeps:

let
  instanceName = "nginx${instanceSuffix}";
  user = instanceName;
  group = instanceName;

  nginxStateDir = "${stateDir}/${instanceName}";
  nginxLogDir = "${nginxStateDir}/logs";
  dependencies = webapps ++ (builtins.attrValues interDeps);
in
import ./nginx.nix {
  inherit createManagedProcess stdenv nginx stateDir forceDisableUserChange runtimeDir cacheDir;
} {
  inherit instanceSuffix;

  dependencies = map (webapp: webapp.pkg) dependencies;

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

        ${stdenv.lib.concatMapStrings (dependencyName:
          let
            dependency = builtins.getAttr dependencyName interDeps;
          in
          ''
            upstream webapp${toString dependency.port} {
              server ${dependency.target.properties.hostname}:${toString dependency.port};
            }
          '') (builtins.attrNames interDeps)}

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
        '') dependencies}
      }
    '';
  };
}

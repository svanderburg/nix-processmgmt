{createManagedProcess, stdenv, lib, writeTextFile, nginx, runtimeDir, stateDir, cacheDir, forceDisableUserChange}:
{port ? 80, webapps ? [], instanceSuffix ? "", instanceName ? "nginx${instanceSuffix}"}:
interDependencies:

let
  user = instanceName;
  group = instanceName;

  nginxStateDir = "${stateDir}/${instanceName}";
  nginxLogDir = "${nginxStateDir}/logs";
  nginxCacheDir = "${cacheDir}/${instanceName}";
in
import ./default.nix {
  inherit createManagedProcess lib nginx stateDir forceDisableUserChange runtimeDir cacheDir;
} {
  inherit instanceName;

  dependencies = map (webapp: webapp.pkg) webapps
    ++ map (interDependency: interDependency.pkgs."${stdenv.system}") (builtins.attrValues interDependencies);

  configFile = writeTextFile {
    name = "nginx.conf";
    text = ''
      pid ${runtimeDir}/${instanceName}.pid;
      error_log ${nginxLogDir}/error.log;

      ${lib.optionalString (!forceDisableUserChange) ''
        user ${user} ${group};
      ''}

      events {
        worker_connections 190000;
      }

      http {
        access_log ${nginxLogDir}/access.log;
        error_log ${nginxLogDir}/error.log;

        proxy_temp_path ${nginxCacheDir}/proxy;
        client_body_temp_path ${nginxCacheDir}/client_body;
        fastcgi_temp_path ${nginxCacheDir}/fastcgi;
        uwsgi_temp_path ${nginxCacheDir}/uwsgi;
        scgi_temp_path ${nginxCacheDir}/scgi;

        ${lib.concatMapStrings (dependency: ''
          upstream webapp${toString dependency.port} {
            server localhost:${toString dependency.port};
          }
        '') webapps}

        ${lib.concatMapStrings (paramName:
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

        ${lib.concatMapStrings (dependency: ''
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

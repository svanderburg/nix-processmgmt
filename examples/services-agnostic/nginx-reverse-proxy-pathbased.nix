{createManagedProcess, stdenv, writeTextFile, nginx, runtimeDir, stateDir, cacheDir, forceDisableUserChange}:
{port ? 80, webapps ? [], instanceSuffix ? "", enableCache ? false}:
interDeps:

let
  instanceName = "nginx${instanceSuffix}";
  user = instanceName;
  group = instanceName;

  nginxStateDir = "${stateDir}/${instanceName}";
  nginxLogDir = "${nginxStateDir}/logs";
  nginxCacheDir = "${cacheDir}/${instanceName}";

  dependencies = webapps ++ (builtins.attrValues interDeps);
in
import ./nginx.nix {
  inherit createManagedProcess stdenv nginx stateDir forceDisableUserChange runtimeDir cacheDir;
} {
  inherit instanceSuffix;

  dependencies = map (webapp: builtins.trace ("we have a: ${toString (builtins.toJSON (builtins.functionArgs webapp.pkg))}") webapp.pkg) webapps;# dependencies;

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
        ${stdenv.lib.optionalString enableCache ''
          ${stdenv.lib.concatMapStrings (dependency:
            ''
              proxy_cache_path ${nginxCacheDir}/${dependency.name} keys_zone=${dependency.name}:8m inactive=5m max_size=128m;
            ''
          ) dependencies}
        ''}

        ${stdenv.lib.concatMapStrings (dependency:
          ''
            upstream ${dependency.name} {
              ip_hash;
              ${if dependency ? targets
                then stdenv.lib.concatMapStrings (target: "server ${target.properties.hostname}:${toString dependency.port};\n") dependency.targets
                else "server localhost:${dependency.port};\n"
              }
            }
          ''
        ) dependencies}

        server {
          ${stdenv.lib.concatMapStrings (dependency:
            ''
              location ${dependency.baseURL} {
                proxy_pass        http://${dependency.name};
                ${stdenv.lib.optionalString enableCache ''
                  proxy_cache       ${dependency.name};
                  proxy_cache_key   $host$uri$is_args$args;
                  proxy_cache_valid 200 5m;
                  proxy_cache_lock  on;
                ''}
              }
            '') dependencies}
        }
      }
    '';
  };
}

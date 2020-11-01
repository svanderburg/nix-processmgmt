{createManagedProcess, stdenv, runCommand, apacheHttpd, php, writeTextFile, logDir, runtimeDir, cacheDir, forceDisableUserChange}:
{instanceSuffix ? "", instanceName ? "httpd${instanceSuffix}", port ? 80, modules ? [], serverName ? "localhost", serverAdmin, documentRoot ? ./webapp, enablePHP ? false, enableCGI ? false, extraConfig ? "", postInstall ? ""}:

let
  user = instanceName;
  group = instanceName;

  baseModules = [
    "mpm_prefork"
    "authn_file"
    "authn_core"
    "authz_host"
    "authz_groupfile"
    "authz_user"
    "authz_core"
    "access_compat"
    "auth_basic"
    "reqtimeout"
    "filter"
    "mime"
    "log_config"
    "env"
    "headers"
    "setenvif"
    "version"
    "unixd"
    "status"
    "autoindex"
    "alias"
    "dir"
  ]
  ++ stdenv.lib.optional enableCGI "cgi";

  apacheLogDir = "${logDir}/${instanceName}";

  phpIni = runCommand "php.ini"
    {
      preferLocalBuild = true;
    }
    ''
      cat ${php}/etc/php.ini > $out
      cat ${php.phpIni} > $out
    '';
in
import ./apache.nix {
  inherit createManagedProcess apacheHttpd cacheDir;
} {
  inherit instanceName postInstall;
  environment = stdenv.lib.optionalAttrs enablePHP {
    PHPRC = phpIni;
  };

  initialize = ''
    mkdir -m0700 -p ${apacheLogDir}

    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${apacheLogDir}
    ''}

    if [ ! -e "${documentRoot}" ]
    then
        mkdir -p "${documentRoot}"
        ${stdenv.lib.optionalString (!forceDisableUserChange) ''
          chown ${user}:${group} ${documentRoot}
        ''}
    fi
  '';

  configFile = writeTextFile {
    name = "httpd.conf";
    text = ''
      ErrorLog "${apacheLogDir}/error_log"
      PidFile "${runtimeDir}/${instanceName}.pid"

      ${stdenv.lib.optionalString (!forceDisableUserChange) ''
        User ${user}
        Group ${group}
      ''}

      ServerName ${serverName}
      ServerRoot ${apacheHttpd}

      Listen ${toString port}

      ${stdenv.lib.concatMapStrings (module: ''
        LoadModule ${module}_module ${apacheHttpd}/modules/mod_${module}.so
      '') baseModules}
      ${stdenv.lib.concatMapStrings (module: ''
        LoadModule ${module.name}_module ${module.module}
      '') modules}
      ${stdenv.lib.optionalString enablePHP ''
        LoadModule php7_module ${php}/modules/libphp7.so
      ''}

      ServerAdmin ${serverAdmin}

      DocumentRoot "${documentRoot}"

      ${stdenv.lib.optionalString enablePHP ''
        <FilesMatch \.php$>
          SetHandler application/x-httpd-php
        </FilesMatch>

        <Directory ${documentRoot}>
          DirectoryIndex index.php
        </Directory>
      ''}

      ${extraConfig}
    '';
  };
}

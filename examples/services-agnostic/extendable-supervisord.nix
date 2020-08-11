{createManagedProcess, writeTextFile, supervisor, runtimeDir, logDir, stateDir}:
{instanceSuffix ? "", instanceName ? "supervisord${instanceSuffix}", inetHTTPServerPort ? 9001, postInstall ? ""}:

let
  includeDir = "${stateDir}/lib/${instanceName}/conf.d";
in
import ./supervisord.nix {
  inherit createManagedProcess supervisor logDir runtimeDir;
} {
  inherit instanceName postInstall;

  initialize = ''
    mkdir -p ${includeDir}
  '';
  configFile = writeTextFile {
    name = "supervisord.conf";
    text = ''
      [supervisord]

      [include]
      files=${includeDir}/*

      [inet_http_server]
      port = 127.0.0.1:${toString inetHTTPServerPort}

      [rpcinterface:supervisor]
      supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
    '';
  };
}

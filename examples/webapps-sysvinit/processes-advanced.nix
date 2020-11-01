{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, cacheDir ? "${stateDir}/cache"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  ids = if builtins.pathExists ./ids-advanced.nix then (import ./ids-advanced.nix).ids else {};

  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange ids;
  };
in
rec {
  webapp1 = rec {
    port = ids.webappPorts.webapp1 or 0;
    dnsName = "webapp1.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "1";
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  webapp2 = rec {
    port = ids.webappPorts.webapp2 or 0;
    dnsName = "webapp2.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "2";
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  webapp3 = rec {
    port = ids.webappPorts.webapp3 or 0;
    dnsName = "webapp3.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "3";
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  webapp4 = rec {
    port = ids.webappPorts.webapp4 or 0;
    dnsName = "webapp4.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "4";
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  nginx = rec {
    port = ids.nginxPorts.nginx or 0;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp1 webapp2 webapp3 webapp4 ];
      inherit port;
    } {};

    requiresUniqueIdsFor = [ "nginxPorts" "uids" "gids" ];
  };

  webapp5 = rec {
    port = ids.webappPorts.webapp5 or 0;
    dnsName = "webapp5.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "5";
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  webapp6 = rec {
    port = ids.webappPorts.webapp6 or 0;
    dnsName = "webapp6.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "6";
    };

    requiresUniqueIdsFor = [ "webappPorts" "uids" "gids" ];
  };

  nginx2 = rec {
    port = ids.nginxPorts.nginx2 or 0;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp5 webapp6 ];
      inherit port;
      instanceSuffix = "2";
    } {};

    requiresUniqueIdsFor = [ "nginxPorts" "uids" "gids" ];
  };
}

{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  sharedConstructors = import ../../../examples/services-agnostic/constructors/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir cacheDir libDir tmpDir forceDisableUserChange processManager;
  };

  constructors = import ../../../examples/webapps-agnostic/constructors/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
    webappMode = null;
  };
in
rec {
  webapp1 = rec {
    port = 5000;
    dnsName = "webapp1.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "1";
    };
  };

  webapp2 = rec {
    port = 5001;
    dnsName = "webapp2.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "2";
    };
  };

  webapp3 = rec {
    port = 5002;
    dnsName = "webapp3.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "3";
    };
  };

  webapp4 = rec {
    port = 5003;
    dnsName = "webapp4.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "4";
    };
  };

  nginx = rec {
    port = if forceDisableUserChange then 8080 else 80;
    webapps = [ webapp1 webapp2 webapp3 webapp4 ];

    pkg = sharedConstructors.nginxReverseProxyHostBased {
      inherit port webapps;
    } {};
  };

  webapp5 = rec {
    port = 5004;
    dnsName = "webapp5.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "5";
    };
  };

  webapp6 = rec {
    port = 5005;
    dnsName = "webapp6.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "6";
    };
  };

  nginx2 = rec {
    port = if forceDisableUserChange then 8081 else 81;
    webapps = [ webapp5 webapp6 ];

    pkg = sharedConstructors.nginxReverseProxyHostBased {
      inherit port webapps;
      instanceSuffix = "2";
    } {};
  };
}

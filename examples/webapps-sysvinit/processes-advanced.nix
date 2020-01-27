{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  constructors = import ./constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange;
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

  nginxReverseProxy = rec {
    port = 8080;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp1 webapp2 webapp3 webapp4 ];
      inherit port;
    } {};
  };

  webapp5 = rec {
    port = 6002;
    dnsName = "webapp5.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "5";
    };
  };

  webapp6 = rec {
    port = 6003;
    dnsName = "webapp6.local";

    pkg = constructors.webapp {
      inherit port;
      instanceSuffix = "6";
    };
  };

  nginxReverseProxy2 = rec {
    port = 8081;

    pkg = constructors.nginxReverseProxy {
      webapps = [ webapp5 webapp6 ];
      inherit port;
      instanceSuffix = "2";
    } {};
  };
}

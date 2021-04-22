{ nixpkgs ? <nixpkgs>
, system ? builtins.currentSystem
, nix-processmgmt ? { outPath = ./.; rev = 1234; }
}:

let
  pkgs = import nixpkgs {};
in
rec {
  tools = import ./tools {
    pkgs = import nixpkgs { inherit system; };
    inherit system;
  };

  tests = {
    builds = import ./tests/builds.nix {
      inherit pkgs nix-processmgmt;
    };

    services = import ./tests/services {
      inherit nixpkgs system;
    };

    multi-process-images = import ./tests/multi-process-images.nix {
      inherit nixpkgs;
    };

    webapps-agnostic = {
      config = import ./tests/webapps-agnostic-config.nix {
        inherit nixpkgs;
      };

      disnix = import ./tests/webapps-agnostic-disnix.nix {
        inherit nixpkgs;
      };

      docker = import ./tests/webapps-agnostic-docker.nix {
        inherit nixpkgs;
      };

      s6-rc = import ./tests/webapps-agnostic-s6-rc.nix {
        inherit nixpkgs;
      };

      supervisord = import ./tests/webapps-agnostic-supervisord.nix {
        inherit nixpkgs;
      };

      supervisord-stateless = import ./tests/webapps-agnostic-supervisord-stateless.nix {
        inherit nixpkgs;
      };

      systemd = import ./tests/webapps-agnostic-systemd.nix {
        inherit nixpkgs;
      };

      systemd-user = import ./tests/webapps-agnostic-systemd-user.nix {
        inherit nixpkgs;
      };

      sysvinit = import ./tests/webapps-agnostic-sysvinit.nix {
        inherit nixpkgs;
      };
    };

    webapps-sysvinit = import ./tests/webapps-sysvinit.nix {
      inherit nixpkgs;
    };
  };

  release = pkgs.releaseTools.aggregate {
    name = "nix-processmgmt";
    constituents = builtins.attrValues tools
      ++ builtins.attrValues tests.builds
      ++ builtins.attrValues tests.webapps-agnostic
      ++ [
        tests.webapps-sysvinit
        tests.multi-process-images
      ];
    meta.description = "Release-critical builds";
  };
}

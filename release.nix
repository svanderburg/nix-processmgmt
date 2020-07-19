{ nixpkgs ? <nixpkgs>
, system ? builtins.currentSystem
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
      ++ builtins.attrValues tests.webapps-agnostic
      ++ [ tests.webapps-sysvinit ];
    meta.description = "Release-critical builds";
  };
}

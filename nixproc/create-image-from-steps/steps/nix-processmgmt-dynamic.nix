{pkgs, common, input, result}:

let
  commonTools = (import ../../../tools {
    inherit pkgs;
    inherit (common) system;
  }).common;

  # If no processes.nix parameter was provided, generate a template
  templateFile = pkgs.writeTextFile {
    name = "processes.nix";
    text = ''
      { pkgs ? import <nixpkgs> { inherit system; }
      , system ? builtins.currentSystem
      , stateDir ? "/var"
      , runtimeDir ? "''${stateDir}/run"
      , logDir ? "''${stateDir}/log"
      , cacheDir ? "''${stateDir}/cache"
      , tmpDir ? (if stateDir == "/var" then "/tmp" else "''${stateDir}/tmp")
      , forceDisableUserChange ? false
      , processManager
      }:

      let
        nix-processmgmt-services = builtins.fetchGit {
          url = https://github.com/svanderburg/nix-processmgmt-services.git;
          ref = "master";
        };

        sharedConstructors = import "''${nix-processmgmt-services}/examples/services-agnostic/constructors.nix" {
          inherit pkgs stateDir runtimeDir logDir cacheDir tmpDir forceDisableUserChange processManager;
        };
      in
      rec {
        /*nginx = rec {
          port = 8080;

          pkg = sharedConstructors.nginxReverseProxyHostBased {
            webapps = [];
            inherit port;
          } {};
        };*/
      }
    '';
  };
in
result // {
  contents = result.contents or []
    ++ [ pkgs.dysnomia commonTools ];

  runAsRoot = result.runAsRoot or "" + ''
    nixproc-init-state --state-dir ${input.stateDir} --runtime-dir ${input.runtimeDir}

    # Provide a processes.nix expression
    mkdir -p /etc/nixproc
  '' + (if input ? exprFile then ''
    cp ${input.exprFile} /etc/nixproc/processes.nix
  '' else ''
    cp ${templateFile} /etc/nixproc/processes.nix
  '')
  + ''
    chmod 644 /etc/nixproc/processes.nix
  '';

  config = result.config or {} // {
    Env = result.config.Env or [] ++ [
      "NIXPROC_PROCESSES=/etc/nixproc/processes.nix"
    ];
  };
}

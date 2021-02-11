{pkgs, common, input, result}:

let
  cmd = pkgs.lib.escapeShellArgs result.config.Cmd;
in
result // pkgs.lib.optionalAttrs (!(input ? bootstrap) || input.bootstrap) {
  runAsRoot = result.runAsRoot or "" + ''
    cat > /bin/bootstrap <<EOF
    #! ${pkgs.stdenv.shell} -e

    # Add nix channel configuration
    nix-channel --add https://nixos.org/channels/nixpkgs-unstable
    nix-channel --update
    nixproc-${input.processManager}-switch &

    # Overwrite the bootstrap script, so that it simply just starts the process manager
    cat > /bin/bootstrap <<EOR
    #! ${pkgs.stdenv.shell} -e
    exec ${cmd}
    EOR

    # Chain load the actual process manager
    exec ${cmd}
    EOF
    chmod 755 /bin/bootstrap
  '';

  config = result.config or {} // {
    Cmd = "/bin/bootstrap";
  };
}

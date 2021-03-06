{pkgs, common, input, result}:

let
  cmd = pkgs.lib.escapeShellArgs result.config.Cmd;

  channelURL = input.channelURL or "https://nixos.org/channels/nixpkgs-unstable";
in
result // pkgs.lib.optionalAttrs (!(input ? bootstrap) || input.bootstrap) {
  runAsRoot = result.runAsRoot or "" + ''
    cat > /bin/bootstrap <<EOF
    #! ${pkgs.stdenv.shell} -e

    # Configure Nix channels
    nix-channel --add ${channelURL}
    nix-channel --update

    # Deploy the processes model (in a child process)
    nixproc-${input.processManager}-switch &

    # Overwrite the bootstrap script, so that it simply just starts the process manager the next time we start the container
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

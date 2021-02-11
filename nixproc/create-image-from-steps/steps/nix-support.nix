{pkgs, common, input, result}:

let
  mkDbExtraCommand = contents: let
    contentsList = if builtins.isList contents then pkgs.lib.unique contents else [ contents ]; in
  ''
    echo "Generating the nix database..."
    echo "Warning: only the database of the deepest Nix layer is loaded."
    echo "         If you want to use nix commands in the container, it would"
    echo "         be better to only have one layer that contains a nix store."

    export NIX_REMOTE=local?root=$PWD
    # A user is required by nix
    # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
    export USER=nobody
    ${pkgs.nix}/bin/nix-store --load-db < ${pkgs.closureInfo {rootPaths = contentsList;}}/registration

    mkdir -p nix/var/nix/gcroots/docker/
    for i in ${pkgs.lib.concatStringsSep " " contentsList}
    do
        ln -s $i nix/var/nix/gcroots/docker/$(basename $i)
    done;
  '';
in
result // rec {
  contents = result.contents or [] ++ (with pkgs; [
    # Nix
    nix.out
    # Needed for SSL authentication
    cacert
    # Needed for fetchgit
    git
    # Needed for downloading compressed tarballs
    gnutar gzip bzip2 xz
  ]);

  extraCommands = result.extraCommands or ""
    + mkDbExtraCommand contents;

  runAsRoot = result.runAsRoot or "" + ''
    # Initialize groups for Nix
    groupadd -g 30000 nixbld
    for i in $(seq 1 30)
    do
        groupadd -g $((30000 + i)) nixbld$i
        useradd -d /var/empty -c "Nix build user $i" -u $((30000 + i)) -g nixbld$i -G nixbld nixbld$i
    done
  '';

  config = result.config or {} // {
    Env = result.config.Env or [] ++ [
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
      "NIX_PATH=/nix/var/nix/profiles/per-user/root/channels"
      "USER=root"
      "PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin"
    ];
  };
}

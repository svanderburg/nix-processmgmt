{pkgs, common, input, result}:

result // pkgs.lib.optionalAttrs (input ? manpages && input.manpages) {
  contents = result.contents ++ (with pkgs; [
    man groff gzip
  ]);

  config = result.config or {} // {
    Env = result.config.Env or [] ++ [ "MANPATH=/share/man:/nix/var/nix/profiles/default/share/man" ];
  };
}

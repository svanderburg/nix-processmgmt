{pkgs, common, input, result}:

let
  disnixTools = (import ../../../../tools {
    inherit pkgs;
    inherit (common) system;
  }).disnix;

  generateCompoundProxy = import ../../util/generate-compound-proxy.nix {
    inherit (pkgs) stdenv lib writeTextFile;
  };

  disnixDataDir = "${pkgs.disnix}/share/disnix";

  emptyProfile = import ../build-disnix-env.nix {
    inherit pkgs disnixDataDir;
    inherit (common) system;
    inherit (input) stateDir runtimeDir forceDisableUserChange extraParams;
    exprFile = null;
  };

  profilePath = "/nix/var/nix/profiles/per-user/root/disnix-coordinator/default";

  script = generateCompoundProxy {
    path = [ pkgs.dysnomia pkgs.disnix ];
    startCommand = "disnix-activate -o ${emptyProfile} ${profilePath}";
    stopCommand = "disnix-activate -o ${profilePath} ${emptyProfile}";
  };
in
result // {
  runAsRoot = result.runAsRoot or "" + ''
    mkdir -p "$(dirname ${profilePath})"
    ln -s ${emptyProfile} ${profilePath}
  '';

  contents = result.contents or [] ++ [ disnixTools ];
  config = result.config or {} // {
    Cmd = [ script ];
  };
}

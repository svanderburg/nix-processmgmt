{pkgs, common, input, result}:

let
  generateCompoundProxy = import ../../util/generate-compound-proxy.nix {
    inherit (pkgs) stdenv lib writeTextFile;
  };

  disnixDataDir = "${pkgs.disnix}/share/disnix";

  profile = import ../build-disnix-env.nix {
    inherit pkgs disnixDataDir;
    inherit (common) system;
    inherit (input) exprFile stateDir runtimeDir forceDisableUserChange extraParams;
  };

  emptyProfile = import ../build-disnix-env.nix {
    inherit pkgs disnixDataDir;
    inherit (common) system;
    inherit (input) stateDir runtimeDir forceDisableUserChange extraParams;
    exprFile = null;
  };

  script = generateCompoundProxy {
    path = [ pkgs.dysnomia pkgs.disnix ];
    startCommand = "disnix-activate ${profile}";
    stopCommand = "disnix-activate -o ${profile} ${emptyProfile}";
  };
in
result // {
  config = result.config or {} // {
    Cmd = [ script ];
  };
}

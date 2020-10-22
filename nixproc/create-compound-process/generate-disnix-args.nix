{ pkgs, system
, exprFile
, stateDir
, runtimeDir
, logDir
, cacheDir
, tmpDir
, forceDisableUserChange
, extraParams
}:

let
  generateCompoundProxyScript = import ./generate-compound-proxy.nix {
    inherit (pkgs) stdenv writeTextFile;
  };

  disnixDataDir = "${pkgs.disnix}/share/disnix";

  profile = import ../create-managed-process/disnix/build-disnix-env.nix {
    inherit pkgs system exprFile stateDir runtimeDir cacheDir logDir tmpDir forceDisableUserChange extraParams disnixDataDir;
  };

  emptyProfile = import ../create-managed-process/disnix/build-disnix-env.nix {
    inherit pkgs system stateDir runtimeDir cacheDir logDir tmpDir forceDisableUserChange extraParams disnixDataDir;
    exprFile = null;
  };

  proxyScript = generateCompoundProxyScript {
    path = [ pkgs.dysnomia pkgs.disnix ];
    startCommand = "disnix-activate ${profile}";
    stopCommand = "disnix-activate -o ${profile} ${emptyProfile}";
  };
in
{ foregroundProcess = proxyScript;
}

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

  profile = import ../create-managed-process/bsdrc/build-bsdrc-env.nix {
    inherit pkgs system exprFile stateDir runtimeDir cacheDir logDir tmpDir forceDisableUserChange extraParams;
  };

  tools = (import ../../tools { inherit pkgs system; }).bsdrc;

  proxyScript = generateCompoundProxyScript {
    startCommand = "${tools}/bin/nixproc-bsdrc-runactivity start ${profile}";
    stopCommand = "${tools}/bin/nixproc-bsdrc-runactivity -r stop ${profile}";
  };
in
{ foregroundProcess = proxyScript;
}

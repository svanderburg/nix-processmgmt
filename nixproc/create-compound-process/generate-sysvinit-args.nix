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

  profile = import ../create-managed-process/sysvinit/build-sysvinit-env.nix {
    inherit pkgs system exprFile stateDir runtimeDir cacheDir logDir tmpDir forceDisableUserChange extraParams;
  };

  tools = (import ../../tools { inherit pkgs system; }).sysvinit;

  proxyScript = generateCompoundProxyScript {
    startCommand = "${tools}/bin/nixproc-sysvinit-runactivity start ${profile}";
    stopCommand = "${tools}/bin/nixproc-sysvinit-runactivity -r stop ${profile}";
  };
in
{ foregroundProcess = proxyScript;
}

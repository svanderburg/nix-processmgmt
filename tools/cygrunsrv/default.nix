{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-cygrunsrv-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-cygrunsrv-switch.in} > $out/bin/nixproc-cygrunsrv-switch
    chmod +x $out/bin/nixproc-cygrunsrv-switch

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-cygrunsrv-deploy.in} > $out/bin/nixproc-cygrunsrv-deploy
    chmod +x $out/bin/nixproc-cygrunsrv-deploy
  '';
}

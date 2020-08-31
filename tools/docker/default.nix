{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-docker-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
        -e "s|@getopt@|${getopt}/bin/getopt|" \
        -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-docker-switch.in} > $out/bin/nixproc-docker-switch
    chmod +x $out/bin/nixproc-docker-switch

    sed -e "s|/bin/bash|$SHELL|" \
        -e "s|@getopt@|${getopt}/bin/getopt|" \
        -e "s|@readlink@|$(type -p readlink)|" \
        -e "s|@xargs@|$(type -p xargs)|" \
        -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-docker-deploy.in} > $out/bin/nixproc-docker-deploy
    chmod +x $out/bin/nixproc-docker-deploy
  '';
}

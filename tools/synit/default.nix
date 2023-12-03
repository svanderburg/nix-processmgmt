{ stdenv, getopt }:

stdenv.mkDerivation {
  name = "nixproc-synit-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-synit-switch.in} > $out/bin/nixproc-synit-switch
    chmod +x $out/bin/nixproc-synit-switch

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-synit-deploy.in} > $out/bin/nixproc-synit-deploy
    chmod +x $out/bin/nixproc-synit-deploy
  '';
}

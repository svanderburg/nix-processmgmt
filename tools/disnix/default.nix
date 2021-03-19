{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-disnix-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-disnix-deploy.in} > $out/bin/nixproc-disnix-deploy
    chmod +x $out/bin/nixproc-disnix-deploy

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-disnix-switch.in} > $out/bin/nixproc-disnix-switch
    chmod +x $out/bin/nixproc-disnix-switch
  '';
}

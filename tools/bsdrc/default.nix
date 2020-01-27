{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-bsdrc-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
        -e "s|@getopt@|${getopt}/bin/getopt|" \
        -e "s|@sed@|$(type -p sed)|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-bsdrc-switch.in} > $out/bin/nixproc-bsdrc-switch
    chmod +x $out/bin/nixproc-bsdrc-switch

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-bsdrc-runactivity.in} > $out/bin/nixproc-bsdrc-runactivity
    chmod +x $out/bin/nixproc-bsdrc-runactivity
  '';
}

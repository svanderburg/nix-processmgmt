{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-sysvinit-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      -e "s|@sysvinitchecks@|${./sysvinitchecks}|" \
      ${./nixproc-sysvinit-switch.in} > $out/bin/nixproc-sysvinit-switch
    chmod +x $out/bin/nixproc-sysvinit-switch

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      -e "s|@sysvinitchecks@|${./sysvinitchecks}|" \
      ${./nixproc-sysvinit-runactivity.in} > $out/bin/nixproc-sysvinit-runactivity
    chmod +x $out/bin/nixproc-sysvinit-runactivity
  '';
}

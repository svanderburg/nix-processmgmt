{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-s6-rc-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-s6-rc-switch.in} > $out/bin/nixproc-s6-rc-switch
    chmod +x $out/bin/nixproc-s6-rc-switch

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@readlink@|$(type -p readlink)|g" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      -e "s|@s6rcchecks@|${./s6-rc-checks}|" \
      ${./nixproc-s6-rc-deploy.in} > $out/bin/nixproc-s6-rc-deploy
    chmod +x $out/bin/nixproc-s6-rc-deploy

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      -e "s|@s6rcchecks@|${./s6-rc-checks}|" \
      ${./nixproc-s6-svscan.in} > $out/bin/nixproc-s6-svscan
    chmod +x $out/bin/nixproc-s6-svscan
  '';
}

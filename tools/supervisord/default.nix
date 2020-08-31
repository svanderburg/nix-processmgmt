{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-supervisord-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
        -e "s|@getopt@|${getopt}/bin/getopt|" \
        -e "s|@readlink@|$(type -p readlink)|" \
        -e "s|@commonchecks@|${../commonchecks}|" \
        -e "s|@supervisordchecks@|${./supervisordchecks}|" \
      ${./nixproc-supervisord-start.in} > $out/bin/nixproc-supervisord-start
    chmod +x $out/bin/nixproc-supervisord-start

    sed -e "s|/bin/bash|$SHELL|" \
        -e "s|@getopt@|${getopt}/bin/getopt|" \
        -e "s|@readlink@|$(type -p readlink)|" \
        -e "s|@commonchecks@|${../commonchecks}|" \
        -e "s|@supervisordchecks@|${./supervisordchecks}|" \
      ${./nixproc-supervisord-switch.in} > $out/bin/nixproc-supervisord-switch
    chmod +x $out/bin/nixproc-supervisord-switch

    sed -e "s|/bin/bash|$SHELL|" \
        -e "s|@getopt@|${getopt}/bin/getopt|" \
        -e "s|@readlink@|$(type -p readlink)|" \
        -e "s|@commonchecks@|${../commonchecks}|" \
        -e "s|@supervisordchecks@|${./supervisordchecks}|" \
      ${./nixproc-supervisord-deploy.in} > $out/bin/nixproc-supervisord-deploy
    chmod +x $out/bin/nixproc-supervisord-deploy

    sed -e "s|/bin/bash|$SHELL|" \
        -e "s|@getopt@|${getopt}/bin/getopt|" \
        -e "s|@readlink@|$(type -p readlink)|" \
        -e "s|@commonchecks@|${../commonchecks}|" \
        -e "s|@supervisordchecks@|${./supervisordchecks}|" \
      ${./nixproc-supervisord-deploy-stateless.in} > $out/bin/nixproc-supervisord-deploy-stateless
    chmod +x $out/bin/nixproc-supervisord-deploy-stateless
  '';
}

{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-build-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@readlink@|$(type -p readlink)|" \
      -e "s|@NIXPROC@|${../../nixproc}|" \
      ${./nixproc-build.in} > $out/bin/nixproc-build
    chmod +x $out/bin/nixproc-build
  '';
}

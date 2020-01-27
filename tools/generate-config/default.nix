{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-generate-config";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@NIXPROC@|${../../nixproc}|" \
      ${./nixproc-generate-config.in} > $out/bin/nixproc-generate-config
    chmod +x $out/bin/nixproc-generate-config
  '';
}

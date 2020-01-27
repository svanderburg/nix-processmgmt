{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-systemd-tools";
  buildCommand = ''
    mkdir -p $out/bin

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@commonchecks@|${../commonchecks}|" \
      ${./nixproc-systemd-switch.in} > $out/bin/nixproc-systemd-switch
    chmod +x $out/bin/nixproc-systemd-switch
  '';
}

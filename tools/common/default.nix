{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-common-tools";
  buildCommand = ''
    mkdir -p $out/bin

    if [ "$(type -p greadlink)" = "" ]
    then
        readlink="$(type -p readlink)"
    else
        readlink="$(type -p greadlink)"
    fi

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e "s|@readlink@|$readlink|" \
      -e "s|@NIXPROC@|${../../nixproc}|" \
      ${./nixproc-build.in} > $out/bin/nixproc-build
    chmod +x $out/bin/nixproc-build

    sed -e "s|/bin/bash|$SHELL|" \
      -e "s|@getopt@|${getopt}/bin/getopt|" \
      -e 's|@DEFAULT_RUNTIME_DIR@|${if stdenv.isLinux || stdenv.isCygwin then "/run" else "/var/run"}|' \
      ${./nixproc-init-state.in} > $out/bin/nixproc-init-state
    chmod +x $out/bin/nixproc-init-state
  '';
}

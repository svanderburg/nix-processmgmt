{stdenv, getopt}:

stdenv.mkDerivation {
  name = "nixproc-id-assign";
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
      ${./nixproc-id-assign.in} > $out/bin/nixproc-id-assign
    chmod +x $out/bin/nixproc-id-assign
  '';
}

{stdenv}:

stdenv.mkDerivation {
  name = "nixproc-chainload-user";
  src = ./.;
  makeFlags = "PREFIX=$(out)";
  dontStrip = true;
}

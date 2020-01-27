with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "webapp";
  src = ./.;
  buildInputs = [ libmicrohttpd ];
  CFLAGS = "-I${libmicrohttpd.dev}/include";
  LDFLAGS = "-L${libmicrohttpd}/lib";
  makeFlags = "PREFIX=$(out)";
  dontStrip = true;
}

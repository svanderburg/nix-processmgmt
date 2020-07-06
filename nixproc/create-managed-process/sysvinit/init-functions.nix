{stdenv, fetchurl, basePackages, runtimeDir}:

let
  basePath = builtins.concatStringsSep ":" (map (package: "${package}/bin") basePackages) + ":\\$PATH";

  src = fetchurl {
    url = http://www.linuxfromscratch.org/lfs/downloads/9.0/lfs-bootscripts-20190524.tar.xz;
    sha256 = "0975wmghhh7j5qify0m170ba2d7vl0km7sw05kclnmwpgivimb38";
  };
in
stdenv.mkDerivation {
  name = "init-functions";

  buildCommand = ''
    tar xfv ${src} lfs-bootscripts-20190524/lfs/lib/services/init-functions

    sed \
      -e "s|/bin:/usr/bin:/sbin:/usr/sbin|${basePath}|" \
      -e "s|/bin/sh|${stdenv.shell}|" \
      -e "s|/bin/echo|echo|" \
      -e "s|/bin/head|head|" \
      -e "s|/var/run|${runtimeDir}|" \
      -e "s|/run/bootlog|${runtimeDir}/bootlog|" \
      lfs-bootscripts-20190524/lfs/lib/services/init-functions > $out
  '';
}

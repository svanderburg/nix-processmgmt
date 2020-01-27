{ stdenv, writeTextFile }:
{ name, initialize }:

writeTextFile {
  name = "${name}-prestart";
  executable = true;
  text = ''
    #! ${stdenv.shell} -e
    ${initialize}
  '';
}

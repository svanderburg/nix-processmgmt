{stdenv, forceDisableUserChange}:

if forceDisableUserChange then
  # Disable the limits command when we want to deploy processes as an unprivileged user
  stdenv.mkDerivation {
    name = "rc.subr";
    src = /etc/rc.subr;

    buildCommand = ''
      sed -e 's|limits -C $_login_class $_limits||' $src > $out
    '';
  }
else
  # Otherwise, simply return the path to the rc subroutines
  "/etc/rc.subr"

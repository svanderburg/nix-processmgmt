{stdenv, forceDisableUserChange}:

stdenv.mkDerivation {
  name = "rc.subr";
  src = /etc/rc.subr;
  # Disable the limits command when we want to deploy processes as an unprivileged user
  buildCommand = if forceDisableUserChange then ''
    sed -e 's|limits -C $_login_class $_limits||' $src > $out
  '' else ''
    cp $src $out
  '';
}

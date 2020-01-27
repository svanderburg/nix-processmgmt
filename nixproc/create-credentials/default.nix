{stdenv}:
{groups, users}:

stdenv.mkDerivation {
  name = "credentials";
  buildCommand = ''
    mkdir -p $out/dysnomia-support/groups

    ${stdenv.lib.concatMapStrings (groupname:
      let
        group = builtins.getAttr groupname groups;
      in
      ''
        cat > $out/dysnomia-support/groups/${groupname} <<EOF
        ${stdenv.lib.concatMapStrings (propertyName:
          let
            value = builtins.getAttr propertyName group;
          in
          "${propertyName}=${stdenv.lib.escapeShellArg value}\n"
        ) (builtins.attrNames group)}
        EOF
      ''
    ) (builtins.attrNames groups)}

    mkdir -p $out/dysnomia-support/users

    ${stdenv.lib.concatMapStrings (username:
      let
        user = builtins.getAttr username users;
      in
      ''
        cat > $out/dysnomia-support/users/${username} <<EOF
        ${stdenv.lib.concatMapStrings (propertyName:
          let
            value = builtins.getAttr propertyName user;
          in
          "${propertyName}=${stdenv.lib.escapeShellArg value}\n"
        ) (builtins.attrNames user)}
        EOF
      ''
    ) (builtins.attrNames users)}
  '';
}

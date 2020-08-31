{stdenv, ids ? {}}:
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
        ${stdenv.lib.optionalString (ids ? gids && builtins.hasAttr groupname ids.gids) ''echo "gid=${toString ids.gids."${groupname}"}" > $out/dysnomia-support/groups/${groupname}''}

        cat >> $out/dysnomia-support/groups/${groupname} <<EOF
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
        ${stdenv.lib.optionalString (ids ? uids && builtins.hasAttr username ids.uids) ''echo "uid=${toString ids.uids."${username}"}" > $out/dysnomia-support/users/${username}''}

        cat >> $out/dysnomia-support/users/${username} <<EOF
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

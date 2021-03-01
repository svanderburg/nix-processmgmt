{stdenv, lib, ids ? {}, forceDisableUserChange}:
{groups ? {}, users ? {}}:

stdenv.mkDerivation {
  name = "credentials";
  buildCommand = ''
    ${lib.optionalString (!forceDisableUserChange && groups != {}) ''
      mkdir -p $out/dysnomia-support/groups

      ${lib.concatMapStrings (groupname:
        let
          group = builtins.getAttr groupname groups;
        in
        ''
          ${lib.optionalString (ids ? gids && builtins.hasAttr groupname ids.gids) ''echo "gid=${toString ids.gids."${groupname}"}" > $out/dysnomia-support/groups/${groupname}''}

          cat >> $out/dysnomia-support/groups/${groupname} <<EOF
          ${lib.concatMapStrings (propertyName:
            let
              value = builtins.getAttr propertyName group;
            in
            "${propertyName}=${lib.escapeShellArg value}\n"
          ) (builtins.attrNames group)}
          EOF
        ''
      ) (builtins.attrNames groups)}
    ''}

    mkdir -p $out/dysnomia-support/users

    ${lib.concatMapStrings (username:
      let
        user = builtins.getAttr username users;
      in
      # If we force disable user changes, we should still create the desired home directory, if applicable
      if forceDisableUserChange then lib.optionalString (user ? createHomeDir && user.createHomeDir) ''
        cat > $out/dysnomia-support/users/${username} <<EOF
        homeDir=${user.homeDir}
        createHomeDir=1
        createHomeDirOnly=1
        EOF
      ''
      # Regular user creation configuration
      else ''
        ${lib.optionalString (ids ? uids && builtins.hasAttr username ids.uids) ''echo "uid=${toString ids.uids."${username}"}" > $out/dysnomia-support/users/${username}''}

        cat >> $out/dysnomia-support/users/${username} <<EOF
        ${lib.concatMapStrings (propertyName:
          let
            value = builtins.getAttr propertyName user;
          in
          "${propertyName}=${lib.escapeShellArg value}\n"
        ) (builtins.attrNames user)}
        EOF
      ''
    ) (builtins.attrNames users)}

    # If we end up having no user configurations, then delete the empty folder
    rmdir --ignore-fail-on-non-empty $out/dysnomia-support/users
  '';
}

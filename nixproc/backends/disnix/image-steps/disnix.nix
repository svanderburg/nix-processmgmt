{pkgs, common, input, result}:

result // {
  contents = result.contents or [] ++ [ pkgs.disnix pkgs.dysnomia ];
}

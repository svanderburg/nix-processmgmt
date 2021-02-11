{pkgs, common, input, result}:

let
  supervisordTools = (import ../../../../tools {
    inherit pkgs;
    inherit (common) system;
  }).supervisord;
in
result // {
  contents = result.contents or [] ++ [ supervisordTools ];

  runAsRoot = result.runAsRoot or "" + ''
    mkdir -p /etc/supervisor/conf.d
    cp ${../supervisord.conf} /etc/supervisor/supervisord.conf
  '';

  config = result.config or {} // {
    Env = result.config.Env or []
      ++ [ "SUPERVISORD_CONF_DIR=/etc/supervisor" ];
  };
}

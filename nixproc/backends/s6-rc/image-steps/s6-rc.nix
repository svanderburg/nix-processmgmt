{pkgs, common, input, result}:

let
  skelDir = pkgs.stdenv.mkDerivation {
    name = "s6-skel-dir";
    buildCommand = ''
      mkdir -p $out
      cd $out

      cat > rc.init <<EOF
      #! ${pkgs.stdenv.shell} -e
      rl="\$1"
      shift

      # Stage 1
      s6-rc-init -c /etc/s6/rc/compiled /run/service

      # Stage 2
      s6-rc -v2 -up change default
      EOF
      chmod 755 rc.init

      cat > rc.shutdown <<EOF
      #! ${pkgs.stdenv.shell} -e
      exec s6-rc -v2 -bDa change
      EOF
      chmod 755 rc.shutdown

      cat > rc.shutdown.final <<EOF
      #! ${pkgs.stdenv.shell} -e
      # Empty
      EOF
      chmod 755 rc.shutdown.final
    '';
  };
in
result // {
 runAsRoot = result.runAsRoot or "" + ''
    # Run s6-linux-init-maker to configure s6-linux-init as an init system
    mkdir -p /etc/s6
    s6-linux-init-maker -c /etc/s6/current -p /bin -m 0022 -f ${skelDir} -N -C -B /etc/s6/current
    mv /etc/s6/current/bin/* /bin
    rmdir etc/s6/current/bin

    # Create s6-log user and group
    groupadd -g 2 s6-log
    useradd -u 2 -d /dev/null -g s6-log s6-log
  '';

  contents = result.contents or [] ++ [ pkgs.s6-linux-init pkgs.s6 pkgs.s6-rc pkgs.execline ];

  config = result.config or {} // {
    cmd = [ "/bin/init" ];
  };
}

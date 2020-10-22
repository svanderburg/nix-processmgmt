{dockerTools, stdenv, pkgs, system}:

{ interactive ? true
, exprFile
, extraParams ? {}
, contents ? []
, runAsRoot ? ""
, config ? {}
, processManager
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, forceDisableUserChange ? false
, ...
}@args:

let
  # Determine which parameters can be propagated to buildImage and which are customizations
  buildImageFormalArgs = builtins.functionArgs dockerTools.buildImage;
  buildImageArgs = builtins.intersectAttrs buildImageFormalArgs args;

  commonTools = (import ../../tools { inherit pkgs; }).common;

  processManagerArgs =
    if processManager == "sysvinit" then import ./generate-sysvinit-args.nix {
      inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams pkgs system;
    }
    else if processManager == "supervisord" then import ./generate-supervisord-args.nix {
      inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams pkgs system;
    }
    else if processManager == "disnix" then import ./generate-disnix-args.nix {
      inherit exprFile stateDir runtimeDir forceDisableUserChange extraParams pkgs system;
    }
    else throw "Unsupported process manager: ${processManager}";

  setupProcessManagement = import ../create-managed-process/docker/setup.nix {
    inherit (pkgs) dockerTools stdenv dysnomia findutils glibc;
    inherit (processManagerArgs) credentialsSpec;
    inherit commonTools stateDir runtimeDir forceDisableUserChange;
  };
in
dockerTools.buildImage ({
  contents = stdenv.lib.optionals interactive [ pkgs.glibc.bin pkgs.bashInteractive pkgs.coreutils pkgs.gnugrep pkgs.findutils pkgs.procps pkgs.utillinux pkgs.less ]
    ++ processManagerArgs.contents
    ++ contents;

  runAsRoot =
    setupProcessManagement
    + processManagerArgs.runAsRoot
    + stdenv.lib.optionalString interactive ''
      mkdir -p /root
      cat > /root/.bashrc << "EOF"
      alias ls='ls --color=auto'

      if [ -n "$PS1" ]
      then
          if [ "$TERM" != "dumb" -o -n "$INSIDE_EMACS" ]
          then
              PROMPT_COLOR="1;31m"
              let $UID && PROMPT_COLOR="1;32m"
              if [ -n "$INSIDE_EMACS" -o "$TERM" == "eterm" -o "$TERM" == "eterm-color" ]
              then
                  # Emacs term mode doesn't support xterm title escape sequence (\e]0;)
                  PS1="\n\[\033[$PROMPT_COLOR\][\u@\h:\w]\\$\[\033[0m\] "
              else
                  PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "
              fi
              if test "$TERM" = "xterm"
              then
                  PS1="\[\033]2;\h:\u:\w\007\]$PS1"
              fi
          fi
      fi
      EOF

      ${runAsRoot}
    '';

  config = stdenv.lib.recursiveUpdate {
    Cmd = processManagerArgs.cmd;
  } config;
} // buildImageArgs)

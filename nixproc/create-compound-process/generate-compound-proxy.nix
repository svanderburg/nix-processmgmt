{stdenv, writeTextFile}:
{startCommand, stopCommand, path ? []}:

writeTextFile {
  name = "compound-proxy-script";
  text = ''
    #! ${stdenv.shell} -e

    _term()
    {
        echo "${stopCommand}"
        ${stopCommand}
        kill "$pid"
        exit 0
    }

    export PATH=${stdenv.lib.escapeShellArg (builtins.concatStringsSep ":" (map (pathComponent: "${pathComponent}/bin") path))}:$PATH

    ${startCommand}

    # Keep process running, but allow it to respond to the TERM and INT signals so that all scripts are stopped properly

    trap _term TERM
    trap _term INT

    tail -f /dev/null & pid=$!
    wait "$pid"
  '';
  executable = true;
}

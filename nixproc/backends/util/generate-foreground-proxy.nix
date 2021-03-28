{stdenv, lib, writeTextFile}:

{ name
, wrapDaemon
, initialize
, executable
, stdenv
, runtimeDir
, instanceName ? null
, pidFile ? (if instanceName == null then null else "${runtimeDir}/${instanceName}.pid")
, user ? null
, nice ? null
, directory ? null
, umask ? null
}:

let
  chainload-user = (import ../../../tools {}).chainload-user;

  _pidFile = if pidFile == null then "${runtimeDir}/$(basename ${executable}).pid" else pidFile;
in
writeTextFile {
  name = "${name}-foregroundproxy.sh";
  text = ''
    #! ${stdenv.shell} -e

    ${initialize}

    ${if wrapDaemon then ''
      export _TOP_PID=$$

      # Handle to SIGTERM and SIGINT signals and forward them to the daemon process
      _term()
      {
          trap "exit 0" TERM
          kill -TERM "$pid"
          kill $_TOP_PID
      }

      _interrupt()
      {
          kill -INT "$pid"
      }

      trap _term SIGTERM
      trap _interrupt SIGINT

      ${lib.optionalString (directory != null) ''
        cd ${directory}
      ''}
      ${lib.optionalString (umask != null) ''
        umask ${umask}
      ''}

      # Start process in the background as a daemon
      ${lib.optionalString (user != null) "${chainload-user}/bin/nixproc-chainload-user ${user} "}${lib.optionalString (nice != null) "nice -n ${nice} "}${executable} "$@"

      # Wait for the PID file to become available. Useful to work with daemons that don't behave well enough.
      count=1 # Start with 1, because 0 returns a non-zero exit status when incrementing it

      while [ ! -f "${_pidFile}" ]
      do
          if [ $count -eq 10 ]
          then
              echo "It does not seem that there isn't any pid file! Giving up!"
              exit 1
          fi

          echo "Waiting for ${_pidFile} to become available..."
          sleep 1

          ((count++))
      done

      # Determine the daemon's PID by using the PID file
      pid=$(cat ${_pidFile})

      # Wait in the background for the PID to terminate
      ${if stdenv.isDarwin then ''
        lsof -p $pid +r 3 &>/dev/null &
      '' else if stdenv.isLinux || stdenv.isCygwin then ''
        tail --pid=$pid -f /dev/null &
      '' else if stdenv.isBSD || stdenv.isSunOS then ''
        pwait $pid &
      '' else throw "Don't know how to wait for process completion on system: ${stdenv.system}"}

      # Wait for the blocker process to complete. We use wait, so that bash can still
      # handle the SIGTERM and SIGINT signals that may be sent to it by a process
      # manager
      blocker_pid=$!
      wait $blocker_pid
    '' else ''
      exec ${lib.optionalString (user != null) "${chainload-user}/bin/nixproc-chainload-user ${user} "}${lib.optionalString (nice != null) "nice -n ${nice} "}"${executable}" "$@"
    ''}
  '';
  executable = true;
}

{ stdenv
, writeTextFile
, daemon
, initFunctions
, createCredentials

# Instructions that are carried out before anything else gets executed
, initialInstructions ? ". ${initFunctions}"
# Command that specifies how to start a daemon
, startDaemon ? "start_daemon"
# Path to the executable that daemonizes a foreground process
, startProcessAsDaemon ? "${daemon}/bin/daemon"
# Command that specifies how to stop a daemon
, stopDaemon ? "killproc"
# Command that specifies how to reload a daemon
, reloadDaemon ? "killproc"
# Command that evaluates the return value of the previous command
, evaluateCommand ? "evaluate_retval"
# Command that shows the status of a daemon
, statusCommand ? "statusproc"
# Default run time directory where PID files are stored
, runtimeDir ? "/var/run"
# Directory in which log files are stored
, logDir ? "/var/log"
# Directory in which temp files are stored
, tmpDir ? "/tmp"
# Specifies the implementation of the restart activity that is used for all sysvinit scripts. Typically, there is little reason to change it.
, restartActivity ? ''
  $0 stop
  sleep 1
  $0 start
''
# Specifies which runlevels are supported
, supportedRunlevels ? stdenv.lib.range 0 6
# The minimum start/stop sequence number
, minSequence ? 0
# The maximum start/stop sequence number
, maxSequence ? 99
# Specifies whether user changing functionality should be disabled or not
, forceDisableUserChange ? false
}:

{
# A name that identifies the process instance
name
# A name that uniquely identifies each process instance. It is used to generate a unique PID file.
, instanceName ? null
# A description that is added to the comments section
, description ? name
# Global instructions that are executed before any activity gets executed
, globalInstructions ? ""
# If not null, the umask will be changed before executing any activities
, umask ? null
# If not null, the nice level be changed before executing any activities
, nice ? null
# If not null, the current working directory will be changed before executing any activities
, directory ? null
# Specifies which packages need to be in the PATH
, path ? []
# An attribute set specifying arbitrary environment variables
, environment ? {}
# Shell instructions that specify how the state of the process should be initialized
, initialize ? ""
# A high level property to specify what process needs to be managed. From this property, the start, stop, reload, status and restart activities are derived.
, process ? null
# Specifies that the process is a daemon. If a process is not a daemon, then the generator will automatically daemonize it.
, processIsDaemon ? true
# Whether to disable logging the daemon process' output
, enableDaemonOutputLogging ? true
# Command-line arguments passed to the process.
, args ? []
# Path to a PID file that the system should use to manage the process. If null, it will use a default path.
, pidFile ? null
# Specifies as which user the process should run. If null, the user privileges will not be changed.
, user ? null
# Specifies which signal should be send to the process to reload its configuration
, reloadSignal ? "-HUP"
# Specifies arbitrary instructions to carry out. Before each instruction the activity will be printed, and after the execution it will evaluate the return status
, instructions ? {}
# Specifies the raw implementation of each activity.
, activities ? {}
# Specifies activities to remove from the generated activities attribute set
, removeActivities ? []
# Specifies in which runlevels the script should be started. From this value, the script will automatically be stopped in the remaining runlevels
, runlevels ? []
# Specifies in which runlevels the script should be started.
, defaultStart ? []
# Specifies in which runlevels the script should be stopped.
, defaultStop ? []
# A list of sysvinit scripts that this scripts depends on. This is used to automatically derive the start and stop sequence. Dependencies will be started first and stopped last.
, dependencies ? []
# Specifies which groups and users that need to be created.
, credentials ? {}
# Arbitrary commands executed after generating the configuration files
, postInstall ? ""
}:

let
  util = import ../util {
    inherit (stdenv) lib;
  };

  isCommonActivity = {activityName}:
    activityName == "start" || activityName == "stop" || activityName == "reload" || activityName == "restart" || activityName == "status" || activityName == "*";

  # Enumerates the activities in a logical order -- the common activities first, then the remaining activities in alphabetical order
  enumerateActivities = activities:
    stdenv.lib.optional (activities ? start) "start"
    ++ stdenv.lib.optional (activities ? stop) "stop"
    ++ stdenv.lib.optional (activities ? reload) "reload"
    ++ stdenv.lib.optional (activities ? restart) "restart"
    ++ stdenv.lib.optional (activities ? status) "status"
    ++ builtins.filter (activityName: !isCommonActivity { inherit activityName; }) (builtins.attrNames activities)
    ++ stdenv.lib.optional (activities ? "*") "*";

  _user = util.determineUser {
    inherit user forceDisableUserChange;
  };

  pidFilesDir = util.determinePIDFilesDir {
    inherit user runtimeDir tmpDir; # We can't use _user because we want to keep the path convention the same
  };

  _pidFile = util.autoGeneratePIDFilePath {
    inherit pidFile instanceName pidFilesDir;
  };

  _instructions = (stdenv.lib.optionalAttrs (process != null) {
    start = {
      activity = "Starting";
      instruction =
        let
          invocationCommand =
            if processIsDaemon then "${startDaemon} ${stdenv.lib.optionalString (_pidFile != null) "-f -p ${_pidFile}"} ${stdenv.lib.optionalString (nice != null) "-n ${nice}"} "
              + util.invokeDaemon {
                inherit process args;
                su = "$(type -p su)"; # the loadproc command requires a full path to an executable
                user = _user;
              }
            else util.daemonizeForegroundProcess {
              daemon = startProcessAsDaemon;
              user = _user;
              pidFile = _pidFile;
              outputLogFile = util.autoGenerateDaemonLogFilePath {
                inherit name instanceName logDir tmpDir enableDaemonOutputLogging;
                user = _user;
              };
              inherit process args pidFilesDir;
            };
        in
        ''
          ${initialize}
          ${invocationCommand}
        '';
    };
    stop = {
      activity = "Stopping";
      instruction = "${stopDaemon} ${stdenv.lib.optionalString (_pidFile != null) "-p ${_pidFile}"} ${process}";
    };
    reload = {
      activity = "Reloading";
      instruction = "${reloadDaemon} ${stdenv.lib.optionalString (_pidFile != null) "-p ${_pidFile}"} ${process} ${reloadSignal}";
    };
  }) // instructions;

  _activities =
    let
      convertedInstructions = stdenv.lib.mapAttrs (name: instruction:
        ''
          log_info_msg "${instruction.activity} ${description}..."
          ${instruction.instruction}
          ${evaluateCommand}
        ''
      ) _instructions;

      defaultActivities = stdenv.lib.optionalAttrs (process != null) {
        status = "${statusCommand} ${stdenv.lib.optionalString (_pidFile != null) "-p ${_pidFile}"} ${process}";
        restart = restartActivity;
      } // {
        "*" = ''
          echo "Usage: $0 {${builtins.concatStringsSep "|" (builtins.filter (activityName: activityName != "*") (enumerateActivities _activities))}}"
          exit 1
        '';
      };
    in
    removeAttrs (convertedInstructions // defaultActivities // activities) removeActivities;

  _defaultStart = if runlevels != [] then stdenv.lib.intersectLists runlevels supportedRunlevels
    else defaultStart;

  _defaultStop = if runlevels != [] then stdenv.lib.subtractLists _defaultStart supportedRunlevels
    else defaultStop;

  _environment = util.appendPathToEnvironment {
    inherit environment path;
  };

  initdScript = writeTextFile {
    inherit name;
    executable = true;
    text = ''
      #! ${stdenv.shell}

      ## BEGIN INIT INFO
      # Provides:      ${name}
    ''
    + stdenv.lib.optionalString (_defaultStart != []) "# Default-Start: ${toString _defaultStart}\n"
    + stdenv.lib.optionalString (_defaultStop != []) "# Default-Stop:  ${toString _defaultStop}\n"
    + stdenv.lib.optionalString (dependencies != []) ''
      # Should-Start:  ${toString (map (dependency: dependency.name) dependencies)}
      # Should-Stop:   ${toString (map (dependency: dependency.name) dependencies)}
    ''
    + ''
      # Description:   ${description}
      ## END INIT INFO

      ${initialInstructions}
      ${globalInstructions}
    ''
    + stdenv.lib.optionalString (umask != null) ''
      umask ${umask}
    ''
    + stdenv.lib.optionalString (directory != null) ''
      cd ${directory}
    ''
    + util.printShellEnvironmentVariables {
      environment = _environment;
      allowSystemPath = true;
    }
    + ''

      case "$1" in
        ${stdenv.lib.concatMapStrings (activityName:
          let
            instructions = builtins.getAttr activityName _activities;
          in
          ''
            ${activityName})
              ${instructions}
              ;;

          ''
        ) (enumerateActivities _activities)}
      esac
    '';
  };

  startSequenceNumber =
    if dependencies == [] then minSequence
    else builtins.head (builtins.sort (a: b: a > b) (map (dependency: dependency.sequence) dependencies)) + 1;

  stopSequenceNumber = maxSequence - startSequenceNumber + minSequence;

  sequenceNumberToString = number:
    if number < 10 then "0${toString number}"
    else toString number;

  credentialsSpec = createCredentials credentials;
in
stdenv.mkDerivation {
  inherit name;

  sequence = startSequenceNumber;

  buildCommand = ''
    mkdir -p $out/etc/rc.d
    cd $out/etc/rc.d

    mkdir -p init.d
    ln -s ${initdScript} init.d/${name}

    ${stdenv.lib.concatMapStrings (runlevel: ''
      mkdir -p rc${toString runlevel}.d
      ln -s ../init.d/${name} rc${toString runlevel}.d/S${sequenceNumberToString startSequenceNumber}${name}
    '') _defaultStart}

    ${stdenv.lib.concatMapStrings (runlevel: ''
      mkdir -p rc${toString runlevel}.d
      ln -s ../init.d/${name} rc${toString runlevel}.d/K${sequenceNumberToString stopSequenceNumber}${name}
    '') _defaultStop}

    ln -s ${credentialsSpec}/dysnomia-support $out/dysnomia-support

    cd $TMPDIR
    ${postInstall}
  '';
}

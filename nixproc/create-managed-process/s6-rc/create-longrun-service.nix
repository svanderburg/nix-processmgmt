{stdenv, createCredentials}:

{ name
# When a service is flagged as essential it will not stop with the command: s6-rc -d change foo, but only: s6-rc -D change foo
, flagEssential ? false
# Script that spawns the long running processes (a foreground process). The run process is typically an execline script, but this is not mandatory
, run
# Script that gets executed when the run process terminates. This finish process is typically an execline script, but this is not mandatory
, finish ? null
# A list of dependencies on other s6-rc services
, dependencies ? []
# Number of the file descriptor that the service can use to send a readiness notification message to. null disables readiness notification
, notificationFd ? null
# A timeout in milliseconds. If the service is still not dead, then it is sent a SIGKILL
, timeoutKill ? null
# By default, a finish script must do its work and exit in less than 5 seconds; if it takes more than that, it is killed. This value allows you to change it.
, timeoutFinish ? null
# Specifies whether the supervised process should become session leader or not
, nosetsid ? false
# The maximum number of service death events that s6-supervise will keep track of (defaults to: 100, maximum: 4096)
, maxDeathTally ? null
# The signal to send to a supervised process, when it is not SIGTERM
, downSignal ? null
# Directory of data files to be included with the service configuration
, data ? null
# Directory of environment variable configuration files to be included with service configuration
, env ? null
# Longrun service for which this service produces data. The corresponding service must also declare this service as a consumer. null specifies that this service is not a producer.
, producerFor ? null
# List of longrun services that this service should consume data from. The corresponding services must also declare this service as a producer.
, consumerFor ? []
# If this file exists along with a consumer-for file, and there is no producer-for file, then a bundle will automatically be created,
# named with the content of the pipeline-name file, and containing all the services in the pipeline that ends at service.
# The pipeline-name file is ignored if service is not a last consumer.
, pipelineName ? null
# Specifies which groups and users that need to be created.
, credentials ? {}
# Arbitrary commands executed after generating the configuration files
, postInstall ? ""
}:

let
  credentialsSpec = createCredentials credentials;

  util = import ./util.nix {
    inherit (stdenv) lib;
  };
in
stdenv.mkDerivation {
  inherit name;
  buildCommand = ''
    mkdir -p $out/etc/s6/sv/${name}
    cd $out/etc/s6/sv/${name}
  ''
  + util.generateStringProperty { value = "longrun"; filename = "type"; }
  + util.generateBooleanProperty { value = flagEssential; filename = "flag-essential"; }
  + util.copyFile { path = run; filename = "run"; }
  + util.copyFile { path = finish; filename = "finish"; }
  + util.generateServiceNameList { services = dependencies; filename = "dependencies"; }
  + util.generateIntProperty { value = notificationFd; filename = "notification-fd"; }
  + util.generateIntProperty { value = timeoutKill; filename = "timeout-kill"; }
  + util.generateIntProperty { value = timeoutFinish; filename = "timeout-finish"; }
  + util.generateBooleanProperty { value = nosetsid; filename = "nosetsid"; }
  + util.generateIntProperty { value = maxDeathTally; filename = "max-death-tally"; }
  + util.generateStringProperty { value = downSignal; filename = "down-signal"; }
  + util.copyDir { path = data; filename = "data"; }
  + util.copyDir { path = env; filename = "env"; }
  + util.generateServiceName { service = producerFor; filename = "producer-for"; }
  + util.generateServiceNameList { services = consumerFor; filename = "consumer-for"; }
  + util.generateStringProperty { value = pipelineName; filename = "pipeline-name"; }
  + ''
    ln -s ${credentialsSpec}/dysnomia-support $out/dysnomia-support

    cd $TMPDIR
    ${postInstall}
  '';
}

{ pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, tmpDir
, forceDisableUserChange
, processManager
}:

let
  createManagedProcess = import ../../nixproc/create-managed-process/agnostic/create-managed-process-universal.nix {
    inherit pkgs runtimeDir stateDir tmpDir forceDisableUserChange processManager;
  };
in
{
  apache = import ./apache.nix {
    inherit createManagedProcess cacheDir;
    inherit (pkgs) apacheHttpd;
  };

  simpleWebappApache = import ./simple-webapp-apache.nix {
    inherit createManagedProcess logDir cacheDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv apacheHttpd php writeTextFile;
  };

  mysql = import ./mysql.nix {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv mysql;
  };

  postgresql = import ./postgresql.nix {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv postgresql;
  };

  tomcat = import ./tomcat.nix {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) stdenv;
    jre = pkgs.jre8;
    tomcat = pkgs.tomcat9;
  };

  simpleAppservingTomcat = import ./simple-appserving-tomcat.nix {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) stdenv;
    jre = pkgs.jre8;
    tomcat = pkgs.tomcat9;
  };

  nginx = import ./nginx.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv nginx;
  };

  nginxReverseProxyHostBased = import ./nginx-reverse-proxy-hostbased.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile nginx;
  };

  nginxReverseProxyPathBased = import ./nginx-reverse-proxy-pathbased.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile nginx;
  };

  mongodb = import ./mongodb.nix {
    inherit createManagedProcess runtimeDir;
    inherit (pkgs) mongodb;
  };

  simpleMongodb = import ./simplemongodb.nix {
    inherit createManagedProcess runtimeDir stateDir forceDisableUserChange;
    inherit (pkgs) stdenv mongodb writeTextFile;
  };

  supervisord = import ./supervisord.nix {
    inherit createManagedProcess runtimeDir logDir;
    inherit (pkgs.pythonPackages) supervisor;
  };

  extendableSupervisord = import ./extendable-supervisord.nix {
    inherit createManagedProcess stateDir runtimeDir logDir;
    inherit (pkgs) writeTextFile;
    inherit (pkgs.pythonPackages) supervisor;
  };

  svnserve = import ./svnserve.nix {
    inherit createManagedProcess runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv subversion;
  };

  simpleInfluxdb = import ./simpleinfluxdb.nix {
    inherit createManagedProcess stateDir;
    inherit (pkgs) influxdb writeTextFile;
  };

  influxdb = import ./influxdb.nix {
    inherit createManagedProcess;
    inherit (pkgs) influxdb;
  };
}

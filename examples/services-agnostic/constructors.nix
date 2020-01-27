{ pkgs
, stateDir
, logDir
, runtimeDir
, tmpDir
, forceDisableUserChange
, processManager
}:

let
  createManagedProcess = import ../../nixproc/create-managed-process/agnostic/create-managed-process-universal.nix {
    inherit pkgs runtimeDir tmpDir forceDisableUserChange processManager;
  };
in
{
  apache = import ./apache.nix {
    inherit createManagedProcess;
    inherit (pkgs) apacheHttpd;
  };

  static-webapp-apache = import ./static-webapp-apache.nix {
    inherit createManagedProcess logDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv apacheHttpd writeTextFile;
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

  simple-appserving-tomcat = import ./simple-appserving-tomcat.nix {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) stdenv;
    jre = pkgs.jre8;
    tomcat = pkgs.tomcat9;
  };
}

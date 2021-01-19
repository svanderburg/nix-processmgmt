{lib}:

rec {
  generateBooleanProperty = {value, filename}:
    lib.optionalString value ''
      touch ${filename}
    '';

  generateStringProperty = {value, filename}:
    lib.optionalString (value != null) ''
      echo "${value}" > ${filename}
    '';

  generateIntProperty = {value, filename}:
    lib.optionalString (value != null) ''
      echo "${toString value}" > ${filename}
    '';

  copyFile = {path, filename}:
    lib.optionalString (path != null) ''
      cp ${path} ${filename}
    '';

  copyDir = {path, filename}:
    lib.optionalString (path != null) ''
      cp -rLv ${path} ${filename}
    '';

  generateServiceName = {service, filename}:
    lib.optionalString (service != null) ''
      echo "${service.name}" > ${filename}
    '';

  generateServiceNameList = {services, filename}:
    lib.optionalString (services != [])
      (lib.concatMapStrings (service: ''
        echo "${service.name}" >> ${filename}
      '') services);
}

{processManager}:

if processManager == null then "managed-process"
else if processManager == "sysvinit" then "sysvinit-script"
else if processManager == "systemd" then "systemd-unit"
else if processManager == "supervisord" then "supervisord-program"
else if processManager == "bsdrc" then "bsdrc-script"
else if processManager == "cygrunsrv" then "cygrunsrv-service"
else if processManager == "launchd" then "launchd-daemon"
else if processManager == "disnix" then "process"
else if processManager == "docker" then "docker-container"
else throw "Unknown process manager: ${processManager}"

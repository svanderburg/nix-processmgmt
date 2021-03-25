{lib}:
{forceDisableUserChange, command}:

lib.optionalString forceDisableUserChange "su - unprivileged -c '"
+ command
+ lib.optionalString forceDisableUserChange "'"

{
  users.extraUsers = {
    unprivileged = {
      uid = 1000;
      group = "users";
      shell = "/bin/sh";
      description = "Unprivileged user";
      home = "/home/unprivileged";
      createHome = true;
    };
  };
}

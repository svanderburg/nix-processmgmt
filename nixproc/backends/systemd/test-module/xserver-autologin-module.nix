{lib, ...}:

{
  # Xserver + PAM only needed for unprivileged systemd deployments
  services.xserver = {
    enable = true;

    displayManager.autoLogin = {
      enable = true;
      user = "unprivileged";
    };

    # Use IceWM as the window manager.
    # Don't use a desktop manager.
    displayManager.defaultSession = lib.mkDefault "none+icewm";
    windowManager.icewm.enable = true;
  };

  # lightdm by default doesn't allow auto login for root, which is
  # required by some nixos tests. Override it here.
  security.pam.services.lightdm-autologin.text = lib.mkForce ''
    auth     requisite pam_nologin.so
    auth     required  pam_succeed_if.so quiet
    auth     required  pam_permit.so

    account  include   lightdm

    password include   lightdm

    session  include   lightdm
  '';
}

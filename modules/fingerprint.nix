{
  # fingerprint aspect — Synaptics 06cb:00bd reader on hornicorn.
  #
  # The device is supported by libfprint's built-in `synaptics` driver
  # (confirmed in 60-autosuspend-libfprint-2.hwdb). No TOD plugin needed.
  #
  # PAM: fprintAuth defaults to services.fprintd.enable, so greetd,
  # swaylock, sudo, and su all get fingerprint support automatically.
  # security.pam.services.login.fprintAuth is left at its default (true)
  # since this system uses greetd, not getty/login — but if you ever add
  # a getty console login you may want to set that to false to avoid
  # blocking on an absent fingerprint.
  #
  # Enroll after first switch:
  #   fprintd-enroll         # enroll right hand index finger (default)
  #   fprintd-enroll -f right-index-finger $USER   # explicit
  #   fprintd-verify         # test it
  den.aspects.fingerprint.nixos.services.fprintd.enable = true;
}

{ inputs, ... }:
{
  # iOS device access. usbmuxd handles the USB multiplexing daemon that lets
  # libimobiledevice tools talk to attached iOS devices; udev rules ensure the
  # device nodes are accessible to normal users. idevicerestore is built from
  # the local fork (which adds the binary that upstream omits by default).
  flake-file.inputs.idevicerestore = {
    url = "github:blessuselessk/idevicerestore-nix/dbcb17fb8751e57f3ad0665ccac48439f3c0c2e5";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.ios = {
    nixos = { pkgs, ... }: {
      services.usbmuxd.enable = true;
      services.udev.packages = [ pkgs.libimobiledevice ];

      # libimobiledevice's udev rules put Apple devices (idVendor 05ac) in
      # the "usbmux" group so usbmuxd can claim them - fine for host-side
      # device access, but it's exactly what blocks USB passthrough to a
      # VM, since the passthrough user isn't (and shouldn't be) in that
      # group. This extra rule forces the device node world-writable so a
      # VM can grab it once usbmuxd is stopped (`systemctl stop usbmuxd`)
      # before passthrough. It still applies even when usbmuxd is running,
      # so it doesn't change normal host-side iOS access - usbmuxd itself
      # already has the device open in that case.
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", MODE="0666"
      '';
    };

    homeManager = { pkgs, ... }: {
      home.packages = [
        inputs.idevicerestore.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.libimobiledevice
      ];
    };
  };
}

{ inputs, ... }:
{
  # iOS device access. usbmuxd handles the USB multiplexing daemon that lets
  # libimobiledevice tools talk to attached iOS devices; udev rules ensure the
  # device nodes are accessible to normal users. idevicerestore is built from
  # the local fork (which adds the binary that upstream omits by default).
  flake-file.inputs.idevicerestore = {
    url = "path:/home/lessuseless/Projects/idevicerestore";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.ios = {
    nixos = { pkgs, ... }: {
      services.usbmuxd.enable = true;
      services.udev.packages = [ pkgs.libimobiledevice ];
    };

    homeManager = { pkgs, ... }: {
      home.packages = [
        inputs.idevicerestore.packages.${pkgs.system}.default
        pkgs.libimobiledevice
      ];
    };
  };
}

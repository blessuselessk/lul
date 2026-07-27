{
  # verbatim port of the hardware scan from /etc/nixos/hardware-configuration.nix
  den.aspects.hornicorn.nixos =
    { lib, config, modulesPath, ... }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/466ade47-2c42-4e30-a977-5a8a4aecd30e";
        fsType = "btrfs";
      };
      fileSystems."/home" = {
        device = "/dev/disk/by-uuid/466ade47-2c42-4e30-a977-5a8a4aecd30e";
        fsType = "btrfs";
        options = [ "subvol=home" ];
      };
      fileSystems."/nix" = {
        device = "/dev/disk/by-uuid/466ade47-2c42-4e30-a977-5a8a4aecd30e";
        fsType = "btrfs";
        options = [ "subvol=nix" ];
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/3062-614F";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/1510cd4a-0ec6-47fc-b77e-2c188db0244b"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}

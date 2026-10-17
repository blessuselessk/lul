{
  # The Intel AX201 Bluetooth radio itself works fine at the kernel level
  # (firmware loads, hci0 shows up in rfkill unblocked) without this - what's
  # actually missing is bluez, the userspace daemon DMS's bluetooth widget
  # talks to over D-Bus. Without hardware.bluetooth.enable, bluetooth.target
  # stays loaded-but-inactive and nothing ever starts bluez, so the widget
  # reports "no adapter detected" even though the hardware is there.
  den.aspects.bluetooth.nixos = {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
  };
}

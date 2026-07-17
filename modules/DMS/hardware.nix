{ ... }:
{
  den.aspects.dms-plugins-hardware = {
    homeManager =
      { pkgs, ... }:
      {
        programs.dank-material-shell.plugins = {
          # Widget / control-center: battery panel with phone-style charge
          # history, detailed stats, and power profiles.
          # Requires: upower, gdbus.
          batteryPlus.src = pkgs.fetchFromGitHub {
            owner = "arcatva";
            repo = "dms-battery-plus";
            rev = "4e653d09174e1edc260f279c42ec2477b6fb2e24";
            hash = "sha256-XEAvnTisFTPs55+uVCDeHXSJthtkE0CU6No29TDyAYY=";
          };

          # Widget: turn displays on/off and adjust brightness of multiple
          # monitors in niri.
          displayManager.src = pkgs.fetchFromGitHub {
            owner = "felri";
            repo = "display-manager-plugin-niri-dank-linux";
            rev = "f789f12a06793212ece407377ad53668b63f76b4";
            hash = "sha256-VFM+NjZwTeUI92lEiWN61OMoT75p7PTmPaSZaMo3K7U=";
          };

          # Widget / control-center: manage Lenovo battery conservation
          # mode and charge thresholds.
          dmsLenovoBatterySettings.src = pkgs.fetchFromGitHub {
            owner = "neoscaler";
            repo = "dms-lenovo-battery-settings";
            rev = "60dc2e76ec14428b543807bf00982fc784fcfe35";
            hash = "sha256-/glhQvb/ZRRW7enXVTUwAUVzf51qrt4a+eaiXgt1/to=";
          };

          # Widget: cozy camera preview in the bar.
          handMirror.src = pkgs.fetchFromGitHub {
            owner = "hthienloc";
            repo = "dms-hand-mirror";
            rev = "d746d14f624bdd8fc00053ea0dca2b6af84fa21a";
            hash = "sha256-e1hOzZoW/juyLsQGAOQW46mGVomSEVlB57GvjegOACA=";
          };

          # Widget: monitor USB drives; mount/unmount, format, resize.
          # Shows notifications on plug/removal.
          usbManager.src = pkgs.fetchFromGitHub {
            owner = "NordicsSys";
            repo = "dms-usb-manager";
            rev = "4dd61c1aa277a280fc05131342bc1cf3936a2a86";
            hash = "sha256-al6/8gFMcy3Vv4867SB7OUNqwCZ3n0ygweg5FvG1xPk=";
          };
        };
      };
  };
}

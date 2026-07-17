{
  den.aspects.web-browsers.nixos =
    { pkgs, lib, ... }:
    {
      programs.firefox.enable = true;

      nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "google-chrome";
      environment.systemPackages = [ pkgs.google-chrome ];
    };
}

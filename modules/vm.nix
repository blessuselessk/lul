# enables `nix run .#vm`. it is very useful to have a VM
# you can edit your config and launch the VM to test stuff
# instead of having to reboot each time.
{ inputs, ... }:
{

  # tty-autologin on tty1 was removed: greetd is configured for vt=1 too
  # (via the dank-material-shell greeter), and the two competing for the
  # same VT is a likely cause of the greeter's niri failing to become DRM
  # master ("assuming unprivileged mode" -> black screen, restart loop).

  # VM-only test password - the real host's `lessuseless` account has its
  # password set manually via `passwd` post-install, not through Nix, so
  # there's nothing to carry over here. `virtualisation.vmVariant` scopes
  # this to `nix run .#vm` only; it never applies to the real system build.
  den.aspects.vm.nixos = { pkgs, ... }: {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    environment.systemPackages = [
      pkgs.qemu
      pkgs.virtiofsd
      (pkgs.writeShellScriptBin "qemu" ''exec ${pkgs.qemu}/bin/qemu-system-x86_64 "$@"'')
    ];
    # claude-desktop's cowork feature checks hardcoded Linux paths for OVMF
    # firmware and virtiofsd that don't exist in NixOS's /usr/ layout.
    systemd.tmpfiles.rules = [
      "L+ /usr/share/OVMF - - - - ${pkgs.OVMF.fd}/FV"
      "L+ /usr/bin/virtiofsd - - - - ${pkgs.virtiofsd}/bin/virtiofsd"
    ];
  };

  den.aspects.hornicorn.nixos =
    { ... }:
    {
      virtualisation.vmVariant.users.users.lessuseless.initialPassword = "test";
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text =
          let
            host = inputs.self.nixosConfigurations.hornicorn.config;
          in
          ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
      };
    };
}

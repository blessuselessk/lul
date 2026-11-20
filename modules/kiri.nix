{ ... }:
{
  # Kiri (github.com/libracoder/kiri): a small container runtime written in
  # Rust that speaks the Docker Engine API. On Linux it runs containers
  # straight on the host kernel, no VM. Not in nixpkgs, so this repackages
  # the upstream kiri-lite .deb (the engine alone: two static musl binaries)
  # and redoes by hand what the .deb's kiri.service and postinst set up.
  # The docker CLI, Compose and buildx come from nixpkgs instead of Kiri's
  # bundled copies.
  den.aspects.kiri.nixos =
    { config, lib, pkgs, ... }:
    let
      version = "0.2.2";

      kiri = pkgs.stdenvNoCC.mkDerivation {
        pname = "kiri";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://github.com/libracoder/kiri/releases/download/v${version}/kiri-lite_${version}_amd64.deb";
          hash = "sha256-JHmBJe5QuyTbhllKnuFGmxAy2bL/19phawbkB2PHI7k=";
        };
        nativeBuildInputs = [ pkgs.dpkg ];
        unpackPhase = "dpkg-deb -x $src .";
        # kiri looks for kiri-init in its own directory, so both go in bin/.
        installPhase = ''
          install -Dm755 usr/bin/kiri usr/bin/kiri-init -t $out/bin
          install -Dm644 usr/share/polkit-1/actions/dev.kiri.host-access.policy -t $out/share/polkit-1/actions
        '';
        meta = {
          description = "Small, fast container runtime that speaks the Docker API";
          homepage = "https://runkiri.com";
          license = lib.licenses.asl20;
          platforms = [ "x86_64-linux" ];
          mainProgram = "kiri";
        };
      };
    in
    {
      environment.systemPackages = [
        kiri
        pkgs.docker-client
        pkgs.docker-compose
        pkgs.docker-buildx
      ];

      # Point every user's docker CLI at Kiri's socket. A user's own
      # DOCKER_HOST or `docker context use` still wins.
      environment.sessionVariables.DOCKER_HOST = "unix:///run/kiri/docker.sock";

      # Members of `kiri` can reach the socket, which is the same as root
      # on this machine (like the `docker` group). Every normal user gets it.
      users.groups.kiri.members = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);

      # Mirrors upstream packaging/linux/kiri.service. Unlike the .deb, it
      # starts at boot, so nobody has to run `kiri host-access` first.
      systemd.services.kiri = {
        description = "Kiri container engine";
        documentation = [ "https://runkiri.com" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          KIRI_SOCKET = "/run/kiri/docker.sock";
          KIRI_SOCKET_GROUP = "kiri";
          HOME = "/var/lib/kiri-daemon";
        };
        serviceConfig = {
          ExecStart = "${kiri}/bin/kiri daemon";
          # Tools that ignore DOCKER_HOST look for /run/docker.sock. Link it
          # to Kiri's socket if nothing else is there, and remove the link on
          # stop only if it is still ours.
          ExecStartPost = "-${pkgs.bash}/bin/sh -c '[ \"$$(readlink /run/docker.sock)\" = /run/kiri/docker.sock ] || [ -e /run/docker.sock ] || [ -L /run/docker.sock ] || ln -s /run/kiri/docker.sock /run/docker.sock'";
          ExecStopPost = "-${pkgs.bash}/bin/sh -c '[ \"$$(readlink /run/docker.sock)\" != /run/kiri/docker.sock ] || rm -f /run/docker.sock'";
          # The daemon creates the cgroups its containers run in.
          Delegate = true;
          KillMode = "mixed";
          Restart = "on-failure";
          RuntimeDirectory = "kiri";
          RuntimeDirectoryMode = "0755";
          StateDirectory = "kiri-daemon";
          StateDirectoryMode = "0700";
          UMask = "0027";
        };
      };
    };
}

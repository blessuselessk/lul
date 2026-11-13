{ ... }:
{
  # Lets prebuilt, dynamically linked generic-Linux executables run on
  # NixOS (which has no /lib64/ld-linux...) - e.g. the standalone `claude`
  # binary that claude.ai/install.sh downloads to ~/.claude/downloads/.
  # See https://nix.dev/permalink/stub-ld.
  den.aspects.nix-ld.nixos = { pkgs, ... }: {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      zstd
      curl
      openssl
      icu
      libxml2
      bzip2
      xz
      systemd

      # Libraries that Playwright's downloaded Chromium/Firefox expect
      # (used by gstack's /browse setup).
      glib
      nss
      nspr
      dbus
      atk
      at-spi2-atk
      at-spi2-core
      cups
      libdrm
      gtk3
      pango
      cairo
      expat
      libxkbcommon
      alsa-lib
      mesa
      libgbm
      fontconfig
      freetype
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
    ];
  };
}

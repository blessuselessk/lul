{ ... }:
{
  # Official Proton Drive CLI (proton.me/support/drive-cli) - terminal-only,
  # there is no official Linux GUI client yet. Not in nixpkgs: two PRs
  # (NixOS/nixpkgs#550980, #557198) were open and unmerged as of
  # 2026-09-28, so this vendors Proton's own published binary directly,
  # the same way modules/obsidian-md/powerdesk.nix pins a third-party
  # release.
  den.aspects.proton-drive.homeManager =
    { pkgs, lib, ... }:
    let
      version = "0.8.0";

      # Proton's own release manifest, which is where these two values come
      # from: https://proton.me/download/drive/cli/version.json - each
      # release lists per-platform download URLs and SHA-512 checksums.
      # Bump: read that JSON for the new "Version" and the "linux-x64"
      # entry's "Sha512CheckSum", set `version` above, then convert the
      # checksum with `nix hash convert --hash-algo sha512 <hex>` and paste
      # the result below (no download needed - fetchurl checks it at build
      # time, in CI, per this repo's apply workflow in the root CLAUDE.md).
      src = pkgs.fetchurl {
        url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
        hash = "sha256-lEPXcXGciSeQ2xfm8C7Nma18U1kzKfOmfHdnfc5XdzU=";
      };

      proton-drive-cli = pkgs.stdenv.mkDerivation {
        pname = "proton-drive-cli";
        inherit version src;

        dontUnpack = true;
        nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

        installPhase = ''
          runHook preInstall
          install -Dm755 $src $out/bin/proton-drive
          runHook postInstall
        '';

        # The binary only NEEDs glibc (confirmed via `ldd` against the
        # fetched binary directly - autoPatchelfHook handles that from
        # stdenv alone) but dlopen()s libsecret at runtime to talk to
        # gnome-keyring (services.gnome.gnome-keyring.enable = true in
        # modules/niri.nix already provides the D-Bus secret-service side of
        # that) for `proton-drive auth login` session storage - NixOS has no
        # global library search path, so that dlopen needs its target on
        # LD_LIBRARY_PATH explicitly or it fails silently at auth time.
        postFixup = ''
          wrapProgram $out/bin/proton-drive \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.libsecret pkgs.dbus ]}
        '';

        meta = {
          description = "Official Proton Drive command-line client";
          homepage = "https://proton.me/support/drive-cli";
          license = lib.licenses.unfree;
          platforms = [ "x86_64-linux" ];
          mainProgram = "proton-drive";
        };
      };
    in
    {
      # Unfree, and home-manager builds its own `pkgs` from its own
      # nixpkgs.config rather than inheriting the system one - same root
      # cause as modules/obsidian-md/obsidian.nix's own unfree handling
      # (den.batteries.unfree only activates through den's aspect-inclusion
      # graph walk, which this repo's homeManager aspects bypass - see that
      # file's comment for the full story).
      #
      # `allowUnfreePackages` (a list), not `allowUnfreePredicate` (a raw
      # function) like obsidian.nix uses: every aspect under hornicorn.nix's
      # `provides.to-users.homeManager.imports` lands in the SAME per-user
      # home-manager `nixpkgs.config`, merged key-by-key via
      # `lib.recursiveUpdate` (home-manager's modules/misc/nixpkgs.nix,
      # `mergeConfig`). That merge only special-cases list-append for
      # `allowUnfreePackages` (and function-composition for
      # `packageOverrides`) - `allowUnfreePredicate` has no such case, so
      # when a second aspect (this one) also set it, the two raw functions
      # collided on the same key and one silently clobbered the other with
      # no eval error, just a `Refusing to evaluate ... unfree` failure on
      # whichever package's name lost. Confirmed live 2026-09-28.
      # nixpkgs' own check-meta.nix ORs `allowUnfreePackages` and
      # `allowUnfreePredicate` together, so this composes correctly
      # alongside obsidian.nix's predicate instead of fighting it.
      nixpkgs.config.allowUnfreePackages = [ "proton-drive-cli" ];

      home.packages = [ proton-drive-cli ];
    };
}

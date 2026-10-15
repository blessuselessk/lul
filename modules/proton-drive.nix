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
      version = "0.9.0";

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
        hash = "sha256-T2b5hLY2EITUZWe49P1IUfQnHrn3fl0YHh7/PIozJQE=";
      };

      # This binary is a `bun build --compile` single-file executable (the
      # app's JS bundle is appended to a real Bun runtime), and Bun's
      # embedded-script detection turned out to be fragile under patchelf:
      # an earlier version of this derivation used autoPatchelfHook, which
      # only grew the file by ~1.2KB (rewriting the interpreter/rpath - no
      # truncation) but silently broke that detection anyway. The patched
      # binary ran, but as plain unmodified Bun - showing Bun's own "Bun is
      # a fast JavaScript runtime..." banner on bare invocation and
      # rejecting `auth` with "a subcommand reserved for future use by
      # Bun", instead of running Proton's embedded CLI. Confirmed by
      # running the pristine fetched file directly through glibc's real
      # ld.so (bypassing Nix entirely): same file, unpatched, correctly
      # printed Proton's own `auth login`/`auth logout` usage. So: NEVER
      # patch this binary's bytes. buildFHSEnv instead gives it a real
      # `/lib64/ld-linux-x86-64.so.2` and library search path inside a
      # mount-namespace sandbox, without touching the binary at all - the
      # same approach NixOS/nixpkgs#550980's draft PR for this exact
      # package already used (dontPatchELF/dontStrip there, for presumably
      # this same reason even though that PR's description didn't say so
      # explicitly).
      protonDriveUnwrapped = pkgs.stdenv.mkDerivation {
        pname = "proton-drive-cli-unwrapped";
        inherit version src;

        dontUnpack = true;
        dontPatchELF = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          install -Dm755 $src $out/bin/proton-drive
          runHook postInstall
        '';
      };

      proton-drive-cli = pkgs.buildFHSEnv {
        name = "proton-drive";
        # libsecret + dbus: `proton-drive auth login` stores its session via
        # Bun.secrets, which talks to the Secret Service over D-Bus -
        # confirmed live that it fails with "libsecret not available"
        # without these. gnome-keyring (the service side of that D-Bus API)
        # is already enabled in modules/niri.nix.
        targetPkgs = pkgs: [ pkgs.libsecret pkgs.dbus ];
        runScript = "${protonDriveUnwrapped}/bin/proton-drive";

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
      nixpkgs.config.allowUnfreePackages = [ "proton-drive" ];

      home.packages = [ proton-drive-cli ];
    };
}

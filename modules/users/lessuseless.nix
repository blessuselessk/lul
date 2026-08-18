{ den, ... }:
{
  # user aspect
  den.aspects.lessuseless = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      den.aspects.telegram
      den.aspects.ios
      den.aspects.llm-agents
      den.aspects.claude-desktop
      den.aspects.claude-settings
      den.aspects.git
    ];

    # os-user battery (auto-activated) forwards this into
    # users.users.lessuseless, merging with what the batteries above set
    # (isNormalUser + home from define-user; wheel + networkmanager from
    # primary-user).
    user =
      { pkgs, ... }:
      let
        iDescriptor = pkgs.appimageTools.wrapType2 {
          pname = "iDescriptor";
          version = "0.5.0";
          src = pkgs.runCommand "iDescriptor-v0.5.0-Linux_x86_64.AppImage" {
            nativeBuildInputs = [ pkgs.unzip ];
          } ''
            unzip ${pkgs.fetchurl {
              url = "https://github.com/iDescriptor/iDescriptor/releases/download/v0.5.0/iDescriptor-v0.5.0-Linux_x86_64.AppImage.zip";
              hash = "sha256-zTCVL7wqe2POh/QxoE7PlNtF/mQgO/IOkNGVqXwHMYQ=";
            }} -d "$TMPDIR"
            cp "$TMPDIR/iDescriptor-v0.5.0-Linux_x86_64.AppImage" "$out"
            chmod +x "$out"
          '';
        };
      in
      {
        description = "lessuseless";
        extraGroups = [ "audio" "input" "libvirtd" ];
        packages = [
          iDescriptor
        ];
        # Keeps this user's systemd --user instance (and everything running
        # in it - claude-desktop-headless below, plus Claude Code sessions)
        # alive at boot regardless of whether lessuseless is the one
        # logged in at the console. Without this, `default.target` for
        # this user only starts on an actual interactive login, and stops
        # the moment it ends - so if aldair or vanya logs in at the
        # console instead, lessuseless's background services would never
        # start (or would die) rather than just running unseen.
        linger = true;
      };
  };
}

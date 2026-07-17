{ ... }:
let
  # converter shares a repo with uptimeBar (monitoring.nix).
  viewerofallRev = "45ab60d67079d23b5c1fbac506aec825e9d3178c";
  viewerofallHash = "sha256-nD+/+iGNi5z0iJ8s0c3WfwDNzOVmW4U7w6SLAnZv3k4=";
in
{
  den.aspects.dms-plugins-productivity = {
    homeManager =
      { pkgs, ... }:
      let
        viewerofallRepo = pkgs.fetchFromGitHub {
          owner = "viewerofall-labs";
          repo = "weather-viewer";
          rev = viewerofallRev;
          hash = viewerofallHash;
        };
      in
      {
        home.packages = [
          pkgs.wl-clipboard # dankVault: wl-copy for clipboard output
          pkgs.python3 # qcalCalendar: CalDAV parsing
          pkgs.pass # dmsPass: standard unix password manager
        ];

        programs.dank-material-shell.plugins = {
          # Launcher: universal unit converter (distance, temperature,
          # weight, speed, …). Trigger: backtick (`).
          converter.src = "${viewerofallRepo}/converter";

          # Desktop widget: RSS/Atom feed reader with auto-refresh.
          dankRssWidget.src = pkgs.fetchFromGitHub {
            owner = "BrendonJL";
            repo = "dms-rss-widget";
            rev = "dcfe5a638ef2143fc18efdd09ef0b80eacbf35f4";
            hash = "sha256-IzqsQYyBjRv9o4cNSQNRfMYBRmirn/LEGCH2c1fhchw=";
          };

          # Widget: locally-saved TODO list in the bar.
          dankTodo.src = pkgs.fetchFromGitHub {
            owner = "deepu105";
            repo = "dms-dank-todo";
            rev = "ff1b82c3061fce3c32c8f65792fa81b928ab35d1";
            hash = "sha256-zX9rtJwq5KyXHG55bQXbV7osAMHTkL9l7qSRqEgh6kI=";
          };

          # Launcher: search and copy passwords from rbw, pass, gopass,
          # or op. Requires: wl-copy. Trigger: @.
          dankVault.src = pkgs.fetchFromGitHub {
            owner = "alcxyz";
            repo = "DankVault";
            rev = "755a9fbe9f62a5e14b4dda63a5fce0c2b40af92c";
            hash = "sha256-pAlNNYYRJQSI368j+1M7Vrbt6EL18hMiYWZk2AjNiH4=";
          };

          # Widget: encoders, decoders, formatters, and converters for devs.
          developerUtilities.src = pkgs.fetchFromGitHub {
            owner = "xxyangyoulin";
            repo = "dms-plugin-developer-utilities";
            rev = "51143ca6a2df83959abfa1ea20643eae8b202992";
            hash = "sha256-UJE2Qf/w4zsx7grS5Q/0HqKExf6Xi8EdQjA0TgSfwTo=";
          };

          # Launcher: search and copy from the `pass` store.
          # Trigger: "pass". Requires: pass.
          dmsPass.src = pkgs.fetchFromGitHub {
            owner = "LouisKottmann";
            repo = "dms-pass";
            rev = "be247a2029efc0df07d57236bad09754384cfb2f";
            hash = "sha256-40U/OTGTFf3lc4Q01/DYLw9xmRHvALq3GHyTytqcNlY=";
          };

          # Widget: view and manage GitHub inbox notifications.
          # Requires: curl, secret-tool (gnome-keyring), jq.
          githubInbox.src = pkgs.fetchFromGitHub {
            owner = "TMS-Namespace";
            repo = "DMS-GitHub-Inbox-Plugin";
            rev = "ab9559df1fe2a21913c98f2758443a7216429d32";
            hash = "sha256-g+KLqRqUBbyzB++tW4E/PyGE0KXDuwAvM9eMP9CLrDk=";
          };

          # Widget: human-agent shared context, tasks, and goal focus.
          # Multiple todo/note/productivity backend support.
          # (authored by lessuseless)
          intentropy.src = pkgs.fetchFromGitHub {
            owner = "blessuselessk";
            repo = "dms-intentropy";
            rev = "b482e8a5da6a63e9c90ebe44f4704506ad0f315d";
            hash = "sha256-S28RrBI5i16CMt26DptcSdP2Nq4mi6GNDnqnnpT3kM8=";
          };

          # Widget: unread IMAP mail indicator with message list popout
          # and desktop notifications.
          mailChecker.src = pkgs.fetchFromGitHub {
            owner = "Rocho-EL-Locho";
            repo = "dms-mail-checker";
            rev = "21a0f60dfb76645b6593200f52bf0a43292925c9";
            hash = "sha256-J09yKmzZanIq34cUOPmHU5w6STp6vXoGfT2C8B53stE=";
          };

          # Widget: CalDAV calendar with events, notifications, and
          # event management. Requires: python3.
          qcalCalendar.src = pkgs.fetchFromGitHub {
            owner = "szabolcsf";
            repo = "dms-qcal-calendar";
            rev = "c0ca502eeb5827f0ac3987c28adf0b5aea7790e3";
            hash = "sha256-LrIYi8PFKZt3dh/wNfPZO42jnSJKpRZjcX2hqpCBt20=";
          };

          # Launcher: search recently opened XDG files.
          # Trigger: "rf". Requires DMS >= 1.5.0.
          recentFiles.src = pkgs.fetchFromGitHub {
            owner = "gouwazi";
            repo = "dms-recent-files";
            rev = "15010449df58ffec4f85acd48f8ee1145de31a1a";
            hash = "sha256-zAzkM1oO50Opja8OskXyCQ7ma3eT+1fikb7bmguG8eM=";
          };

          # Launcher: web search with configurable search engines.
          # Trigger: @.
          webSearch.src = pkgs.fetchFromGitHub {
            owner = "devnullvoid";
            repo = "dms-web-search";
            rev = "821f5b437ea96739ce1cbc85ce324fb55e8884bb";
            hash = "sha256-UqFgAjW2A75dtlvOZkq4Vv/v/DROoc/ouCXBaVlksPI=";
          };
        };
      };
  };
}

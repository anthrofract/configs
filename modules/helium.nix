{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  heliumExtensionUpdateUrl = "https://services.helium.imput.net/ext";

  ompBrowserRelayExtensionDir = "/home/${config.secrets.identities.personal.userName}/.omp/browser-relay/extension";

  # Chromium derives an unpacked extension's ID from its path: hex digits of its SHA-256 become letters a-p.
  ompBrowserRelayExtensionId =
    builtins.replaceStrings (lib.stringToCharacters "0123456789abcdef")
      (lib.stringToCharacters "abcdefghijklmnop")
      (builtins.substring 0 32 (builtins.hashString "sha256" ompBrowserRelayExtensionDir));

  # omp stamps the extension with its version at install time; a throwaway HOME discards its registrations.
  ompBrowserRelayExtensionFor =
    pkgs: omp:
    pkgs.runCommand "omp-browser-relay-extension" { nativeBuildInputs = [ omp ]; } ''
      HOME="$TMPDIR" omp browser-relay install --no-chrome --dir "$out" > /dev/null
    '';

  baseHeliumPackageFor =
    pkgs:
    inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      withWidevine = false;
    };

  heliumPackageFor =
    pkgs:
    let
      helium = baseHeliumPackageFor pkgs;
    in
    if pkgs.stdenv.hostPlatform.isLinux then
      pkgs.symlinkJoin {
        name = "${helium.name}-omp-browser-relay";
        paths = [ helium ];
        postBuild = ''
          mv "$out/bin/helium" "$out/bin/.helium-wrapped"
          cat > "$out/bin/helium" <<EOF
          #!${pkgs.runtimeShell}
          exec -a "\$0" "$out/bin/.helium-wrapped" --disable-features=OverlayScrollbar --load-extension="\$HOME/.omp/browser-relay/extension" "\$@"
          EOF
          chmod +x "$out/bin/helium"
        '';
      }
    else
      helium;

  extensionIds = {
    darkReader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    kagi = "cdglnehniifkbagbbombnjghhcihifij";
    keepassxcBrowser = "oboonakemofpalcgghocfoadofidjkkk";
    ublockOrigin = "blockjmkbacgjkknlgpkjjiijinjdanf";
    userAgentSwitcher = "bhchdcejhohfmigjafbampogmaanbfkg";
    vimiumC = "hfjbmagddngcpeloejdejnfgbamkjaeg";
  };

  installedExtensionIds = [
    extensionIds.darkReader
    extensionIds.kagi
    extensionIds.keepassxcBrowser
    extensionIds.userAgentSwitcher
    extensionIds.vimiumC
  ];

  browserDefaults = {
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Kagi";
    DefaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://kagi.com/api/autosuggest?q={searchTerms}";
    RestoreOnStartup = 1;
    SearchSuggestEnabled = true;
  };

  policy = browserDefaults // {
    ExtensionInstallForcelist = map (id: "${id};${heliumExtensionUpdateUrl}") installedExtensionIds;

    ExtensionInstallAllowlist = [
      extensionIds.darkReader
      extensionIds.kagi
      extensionIds.keepassxcBrowser
      extensionIds.ublockOrigin
      extensionIds.userAgentSwitcher
      extensionIds.vimiumC
    ];

    ExtensionInstallSources = [ "${lib.removeSuffix "/ext" heliumExtensionUpdateUrl}/*" ];
  };

in
{
  flake.commonModules.helium =
    { pkgs, latestPkgs, ... }:
    {
      home-manager.sharedModules = [
        (
          { lib, ... }:
          {
            home.file.".omp/browser-relay/extension" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
              source = ompBrowserRelayExtensionFor pkgs latestPkgs.omp;
              recursive = true;
              force = true;
            };

            home.sessionVariables.BROWSER = "helium";

            xdg.mimeApps.defaultApplications = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
              lib.genAttrs [
                "application/pdf"
                "application/rdf+xml"
                "application/rss+xml"
                "application/xhtml+xml"
                "application/xhtml_xml"
                "application/xml"
                "image/gif"
                "image/jpeg"
                "image/png"
                "image/webp"
                "text/html"
                "text/xml"
                "x-scheme-handler/http"
                "x-scheme-handler/https"
              ] (name: "helium.desktop")
            );
          }
        )
      ];
    };

  flake.nixosModules.helium =
    {
      pkgs,
      lib,
      latestPkgs,
      ...
    }:
    {
      imports = [ self.commonModules.helium ];

      environment.systemPackages = [
        (
          # Chromium on native Wayland + NVIDIA whites out Google Meet effects.
          # if lib.elem "nvidia" config.services.xserver.videoDrivers then
          #   heliumX11PackageFor pkgs
          # else
          heliumPackageFor pkgs
        )
      ];

      environment.etc."chromium/policies/managed/helium.json".text = lib.toJSON policy;

      environment.etc."chromium/native-messaging-hosts/sh.omp.browser.json".text = lib.toJSON {
        name = "sh.omp.browser";
        description = "omp browser native messaging host";
        # Like omp's own launcher, keeps the origin arguments Chrome passes away from the omp CLI.
        path = pkgs.writeShellScript "omp-native-host" ''
          exec ${lib.getExe latestPkgs.omp} browser-relay native-host
        '';
        type = "stdio";
        allowed_origins = [ "chrome-extension://${ompBrowserRelayExtensionId}/" ];
      };
    };

  flake.darwinModules.helium =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.helium ];

      environment.systemPackages = [ (heliumPackageFor pkgs) ];

      # Ordinary preferences are user-overridable defaults, not MDM policy.
      system.defaults.CustomUserPreferences."net.imput.helium" = browserDefaults;

      home-manager.sharedModules = [
        {
          home.file =
            lib.genAttrs
              (map (
                id: "Library/Application Support/net.imput.helium/External Extensions/${id}.json"
              ) installedExtensionIds)
              (_: {
                text = builtins.toJSON {
                  external_update_url = heliumExtensionUpdateUrl;
                };
              });
        }
      ];
    };
}

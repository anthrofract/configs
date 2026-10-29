{
  self,
  inputs,
  lib,
  ...
}:
let
  heliumExtensionUpdateUrl = "https://services.helium.imput.net/ext";

  ompBrowserRelayExtensionFiles = [
    "background.js"
    "LICENSE"
    "manifest.json"
    "options.html"
    "options.js"
    "THIRD-PARTY-NOTICES.txt"
  ];

  ompBrowserRelayExtensionFor =
    pkgs: latestPkgs:
    let
      assets = "${latestPkgs.omp.src}/packages/coding-agent/src/tools/browser/relay/extension-assets";
    in
    pkgs.runCommand "omp-browser-relay-extension" { } ''
      install -Dm444 "${assets}/background.js.txt" "$out/background.js"
      install -Dm444 "${assets}/LICENSE.txt" "$out/LICENSE"
      install -Dm444 "${assets}/manifest.json.txt" "$out/manifest.json"
      install -Dm444 "${assets}/options.html.txt" "$out/options.html"
      install -Dm444 "${assets}/options.js.txt" "$out/options.js"
      install -Dm444 "${assets}/THIRD-PARTY-NOTICES.txt" "$out/THIRD-PARTY-NOTICES.txt"
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
          exec -a "\$0" "$out/bin/.helium-wrapped" --load-extension="\$HOME/.omp/browser-relay/extension" "\$@"
          EOF
          chmod +x "$out/bin/helium"
        '';
      }
    else
      helium;

  # heliumX11PackageFor =
  #   pkgs:
  #   pkgs.symlinkJoin {
  #     name = "helium-x11";
  #     paths = [ (heliumPackageFor pkgs) ];
  #     nativeBuildInputs = [ pkgs.makeWrapper ];
  #     postBuild = ''
  #       wrapProgram "$out/bin/helium" \
  #         --set NIXOS_OZONE_WL 0 \
  #         --add-flags "--ozone-platform=x11"
  #     '';
  #   };

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
            home.file = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
              lib.genAttrs (map (name: ".omp/browser-relay/extension/${name}") ompBrowserRelayExtensionFiles)
                (path: {
                  force = true;
                  source = "${ompBrowserRelayExtensionFor pkgs latestPkgs}/${builtins.baseNameOf path}";
                })
            );

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
    { pkgs, lib, ... }:
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

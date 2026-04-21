{
  self,
  inputs,
  lib,
  ...
}:
let
  heliumExtensionUpdateUrl = "https://services.helium.imput.net/ext";

  heliumPackageFor = pkgs: inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;

  heliumX11PackageFor =
    pkgs:
    pkgs.symlinkJoin {
      name = "helium-x11";
      paths = [ (heliumPackageFor pkgs) ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/helium" \
          --set NIXOS_OZONE_WL 0 \
          --add-flags "--ozone-platform=x11"
      '';
    };

  extensionIds = {
    darkReader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    kagi = "cdglnehniifkbagbbombnjghhcihifij";
    keepassxcBrowser = "oboonakemofpalcgghocfoadofidjkkk";
    ublockOrigin = "blockjmkbacgjkknlgpkjjiijinjdanf";
    userAgentSwitcher = "bhchdcejhohfmigjafbampogmaanbfkg";
  };

  policy = {
    ExtensionInstallForcelist = [
      "${extensionIds.darkReader};${heliumExtensionUpdateUrl}"
      "${extensionIds.kagi};${heliumExtensionUpdateUrl}"
      "${extensionIds.keepassxcBrowser};${heliumExtensionUpdateUrl}"
      "${extensionIds.userAgentSwitcher};${heliumExtensionUpdateUrl}"
    ];

    ExtensionInstallAllowlist = [
      extensionIds.darkReader
      extensionIds.kagi
      extensionIds.keepassxcBrowser
      extensionIds.ublockOrigin
      extensionIds.userAgentSwitcher
    ];

    ExtensionInstallSources = [ "${lib.removeSuffix "/ext" heliumExtensionUpdateUrl}/*" ];

    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Kagi";
    DefaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://kagi.com/api/autosuggest?q={searchTerms}";
    RestoreOnStartup = 1;
    SearchSuggestEnabled = true;
  };

in
{
  flake.commonModules.helium =
    { pkgs, ... }:
    {
      home-manager.sharedModules = [
        (
          { lib, ... }:
          {
            home.sessionVariables.BROWSER = "helium";

            xdg.mimeApps.defaultApplications = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
              builtins.listToAttrs (
                map
                  (name: {
                    inherit name;
                    value = "helium.desktop";
                  })
                  [
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
                  ]
              )
            );
          }
        )
      ];
    };

  flake.nixosModules.helium =
    { config, pkgs, ... }:
    {
      imports = [ self.commonModules.helium ];

      environment.systemPackages = [
        (
          # Chromium on native Wayland + NVIDIA whites out Google Meet effects.
          if builtins.elem "nvidia" config.services.xserver.videoDrivers then
            heliumX11PackageFor pkgs
          else
            heliumPackageFor pkgs
        )
      ];

      environment.etc."chromium/policies/managed/helium.json".text = builtins.toJSON policy;
    };

  flake.darwinModules.helium =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      managedPolicyPlist = lib.generators.toPlist { escape = true; } policy;
    in
    {
      imports = [ self.commonModules.helium ];

      environment.systemPackages = [ (heliumPackageFor pkgs) ];

      system.activationScripts.script.text = lib.mkAfter ''
        ${config.system.activationScripts.helium.text}
      '';

      system.activationScripts.helium.text = ''
        echo "setting up helium policy..."
        /usr/bin/install -d -m 755 "/Library/Managed Preferences"
        /bin/cat > "/Library/Managed Preferences/net.imput.helium.plist" <<'PLIST_EOF'
        ${managedPolicyPlist}
        PLIST_EOF
        /usr/sbin/chown root:wheel "/Library/Managed Preferences/net.imput.helium.plist"
        /bin/chmod 0644 "/Library/Managed Preferences/net.imput.helium.plist"
      '';
    };
}

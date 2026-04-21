{
  self,
  inputs,
  lib,
  ...
}:
let
  heliumExtensionUpdateUrl = "https://services.helium.imput.net/ext";

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
      extensionIds.ublockOrigin
      extensionIds.kagi
      extensionIds.keepassxcBrowser
      extensionIds.darkReader
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
    let
      heliumPackage = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      environment.systemPackages = [ heliumPackage ];

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
    { ... }:
    {
      imports = [ self.commonModules.helium ];

      environment.etc."chromium/policies/managed/helium.json".text = builtins.toJSON policy;
    };

  flake.darwinModules.helium =
    { config, lib, ... }:
    let
      managedPolicyPlist = lib.generators.toPlist { escape = true; } policy;
    in
    {
      imports = [ self.commonModules.helium ];

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

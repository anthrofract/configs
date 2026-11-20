{ self, ... }:
{
  flake.commonModules.pki = {
    # Distrust every eMudhra root after the October 2026 intermediate CA key
    # compromise. NSS 3.131.1 already removed the others.
    security.pki.caCertificateBlacklist = [ "emSign Root CA - G1" ];
  };

  flake.nixosModules.pki =
    { pkgs, ... }:
    {
      imports = [ self.commonModules.pki ];

      # Trust the NextDNS Root CA so block pages can be served over HTTPS
      security.pki.certificateFiles = [
        (pkgs.fetchurl {
          url = "https://nextdns.io/ca";
          hash = "sha256-yl+2q4H/a8SLGv4Mt+g8+03uy9ihZxACbsj3uCTog34=";
        })
      ];
    };
}

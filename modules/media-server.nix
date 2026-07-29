{ inputs, ... }:
{
  flake.nixosModules.media-server =
    { config, pkgs, ... }:
    {
      imports = [ inputs.nixarr.nixosModules.default ];

      nixarr = {
        enable = true;
        mediaDir = "/data/media";
        stateDir = "/data/.state/nixarr";

        vpn.enable = false;

        jellyfin = {
          enable = true;
          openFirewall = true;
        };

        transmission = {
          enable = true;
          extraSettings."utp-enabled" = true;
        };

        sonarr = {
          enable = true;
          settings-sync.transmission = {
            enable = true;
            config.fields.tvCategory = "sonarr";
          };
        };

        radarr = {
          enable = true;
          settings-sync.transmission.enable = true;
        };

        prowlarr = {
          enable = true;
          settings-sync = {
            radarr.enable = true;
            sonarr.enable = true;
          };
        };

        bazarr.enable = true;

        seerr = {
          enable = true;
          package = pkgs.seerr.overrideAttrs (oldAttrs: {
            postInstall = (oldAttrs.postInstall or "") + ''
              cp next.config.ts $out/share/next.config.ts
              ln -s ${config.nixarr.stateDir}/seerr/cache/next $out/share/.next/cache
            '';
          });
        };

        recyclarr = {
          enable = true;
          configuration = {
            radarr.movies = {
              base_url = "http://127.0.0.1:${toString config.nixarr.radarr.port}";
              api_key = "!env_var RADARR_API_KEY";
              delete_old_custom_formats = true;
              quality_definition.type = "movie";
              quality_profiles = [
                {
                  trash_id = "64fb5f9858489bdac2af690e27c8f42f"; # UHD Bluray + WEB
                  reset_unmatched_scores.enabled = true;
                  upgrade = {
                    allowed = true;
                    until_quality = "Bluray-2160p";
                    until_score = 10000;
                  };
                  qualities = [
                    { name = "Bluray-2160p"; }
                    {
                      name = "WEB 2160p";
                      qualities = [
                        "WEBDL-2160p"
                        "WEBRip-2160p"
                      ];
                    }
                    { name = "Bluray-1080p"; }
                    {
                      name = "WEB 1080p";
                      qualities = [
                        "WEBDL-1080p"
                        "WEBRip-1080p"
                      ];
                    }
                  ];
                }
              ];
              custom_formats = [
                {
                  trash_ids = [ "493b6d1dbec3c3364c59d7607f7e3405" ]; # HDR
                  assign_scores_to = [
                    {
                      name = "UHD Bluray + WEB";
                      score = 500;
                    }
                  ];
                }
                {
                  trash_ids = [ "b337d6812e06c200ec9a2d3cfa9d20a7" ]; # Dolby Vision
                  assign_scores_to = [
                    {
                      name = "UHD Bluray + WEB";
                      score = 1000;
                    }
                  ];
                }
                {
                  trash_ids = [ "caa37d0df9c348912df1fb1d88f9273a" ]; # HDR10+
                  assign_scores_to = [
                    {
                      name = "UHD Bluray + WEB";
                      score = 100;
                    }
                  ];
                }
                {
                  trash_ids = [
                    "923b6abef9b17f937fab56cfcf89e1f1" # Dolby Vision without HDR fallback
                    "cae4ca30163749b891686f95532519bd" # AV1
                  ];
                  assign_scores_to = [
                    {
                      name = "UHD Bluray + WEB";
                      score = -10000;
                    }
                  ];
                }
              ];
            };

            sonarr.series = {
              base_url = "http://127.0.0.1:${toString config.nixarr.sonarr.port}";
              api_key = "!env_var SONARR_API_KEY";
              delete_old_custom_formats = true;
              quality_definition.type = "series";
              quality_profiles = [
                {
                  trash_id = "dfa5eaae7894077ad6449169b6eb03e0"; # WEB-2160p alternative
                  reset_unmatched_scores.enabled = true;
                }
              ];
              custom_formats = [
                {
                  trash_ids = [ "505d871304820ba7106b693be6fe4a9e" ]; # HDR
                  assign_scores_to = [
                    {
                      name = "WEB-2160p (Alternative)";
                      score = 500;
                    }
                  ];
                }
                {
                  trash_ids = [ "7c3a61a9c6cb04f52f1544be6d44a026" ]; # Dolby Vision
                  assign_scores_to = [
                    {
                      name = "WEB-2160p (Alternative)";
                      score = 1000;
                    }
                  ];
                }
                {
                  trash_ids = [ "0c4b99df9206d2cfac3c05ab897dd62a" ]; # HDR10+
                  assign_scores_to = [
                    {
                      name = "WEB-2160p (Alternative)";
                      score = 100;
                    }
                  ];
                }
                {
                  trash_ids = [
                    "9b27ab6498ec0f31a3353992e19434ca" # Dolby Vision without HDR fallback
                    "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1
                  ];
                  assign_scores_to = [
                    {
                      name = "WEB-2160p (Alternative)";
                      score = -10000;
                    }
                  ];
                }
              ];
            };
          };
        };
      };

      services = {
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
          publish = {
            enable = true;
            addresses = true;
          };
        };

        jellyfin = {
          forceEncodingConfig = true;
          hardwareAcceleration = {
            enable = true;
            device = "/dev/dri/renderD128";
            type = "vaapi";
          };
          transcoding = {
            enableHardwareEncoding = true;
            enableIntelLowPowerEncoding = true;
            enableToneMapping = true;
            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
              hevc10bit = true;
              mpeg2 = true;
              vc1 = true;
              vp8 = true;
              vp9 = true;
            };
            hardwareEncodingCodecs.hevc = true;
          };
        };

        nginx.virtualHosts."sonarr.${config.services.reverse-proxy.domain}".locations."/".extraConfig = ''
          proxy_connect_timeout 60s;
          proxy_send_timeout 300s;
          proxy_read_timeout 300s;
        '';

        prowlarr.settings.auth.required = "DisabledForLocalAddresses";
        radarr.settings.auth.required = "DisabledForLocalAddresses";
        sonarr.settings.auth.required = "DisabledForLocalAddresses";

        reverse-proxy.services = {
          bazarr.port = config.nixarr.bazarr.port;
          jellyfin = {
            port = config.nixarr.jellyfin.port;
            websocketPaths = [ "/socket" ];
          };
          prowlarr.port = config.nixarr.prowlarr.port;
          radarr.port = config.nixarr.radarr.port;
          seerr.port = config.nixarr.seerr.port;
          sonarr.port = config.nixarr.sonarr.port;
          transmission = {
            port = config.nixarr.transmission.uiPort;
            hostHeader = "127.0.0.1";
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${config.nixarr.stateDir}/seerr/cache/next 0750 seerr media -"
      ];

      users.users.jellyfin.extraGroups = [
        "render"
        "video"
      ];
    };
}

{ ... }:
{
  flake.nixosModules.local-ai =
    { config, pkgs, ... }:
    {
      # Ollama
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        openFirewall = true;
        host = "0.0.0.0";
        environmentVariables = {
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q4_0";
          OLLAMA_CONTEXT_LENGTH = "131072";
        };
        loadModels = [
          "qwen3.6:27b"
          "qwen3.6:27b-mtp-q4_K_M"
          "fredrezones55/Qwen3.6-27B-Uncensored-HauhauCS-Balanced:IQ4_XS"
        ];
      };
      systemd.services.ollama = {
        wantedBy = pkgs.lib.mkForce [ ];
        partOf = [ "local-ai.service" ];
      };
      systemd.services.ollama-model-loader = {
        wantedBy = pkgs.lib.mkForce [ ];
        partOf = [ "local-ai.service" ];
      };

      # Open Webui
      services.open-webui = {
        enable = true;
        openFirewall = false;
        host = "127.0.0.1";
        environment = {
          WEBUI_AUTH = "False";
          WEBUI_URL = "${config.services.reverse-proxy.protocol}://openwebui.${config.services.reverse-proxy.domain}";
        };
      };
      services.reverse-proxy.services.openwebui = {
        port = config.services.open-webui.port;
        websocketPaths = [ "/ws/socket.io/" ];
      };
      systemd.services.open-webui = {
        wantedBy = pkgs.lib.mkForce [ ];
        partOf = [ "local-ai.service" ];
      };

      # Unified service
      systemd.services.local-ai = {
        description = "Local AI services";
        wantedBy = pkgs.lib.mkForce [ ];
        wants = [
          "ollama.service"
          "ollama-model-loader.service"
          "open-webui.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
        };
      };
    };
}

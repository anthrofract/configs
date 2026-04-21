{ ... }:
{
  flake.nixosModules.local-ai =
    { pkgs, ... }:
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
          OLLAMA_CONTEXT_LENGTH = "65536";
        };
        loadModels = [
          "deepseek-r1:14b"
          "qwen3-coder:30b"
          "qwen3:30b-a3b"
        ];
      };
      systemd.services.ollama.wantedBy = pkgs.lib.mkForce [ ];
      systemd.services.ollama-model-loader.wantedBy = pkgs.lib.mkForce [ ];

      # Open Webui
      services.open-webui = {
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
      };
      systemd.services.open-webui.wantedBy = pkgs.lib.mkForce [ ];
    };
}

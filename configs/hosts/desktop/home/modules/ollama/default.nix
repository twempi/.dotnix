{pkgs, ...}: {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;

    host = "127.0.0.1";
    port = 11434;
    openFirewall = false;

    environmentVariables = {
      # Default context window: 8,192 tokens.
      OLLAMA_CONTEXT_LENGTH = "8192";

      # Keep the model loaded for 5 minutes after use.
      OLLAMA_KEEP_ALIVE = "5m";

      # Process one request and keep one model loaded at a time.
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_MAX_LOADED_MODELS = "1";

      # Reduce memory usage for attention and the context cache.
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };
}

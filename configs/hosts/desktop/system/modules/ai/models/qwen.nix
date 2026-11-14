{
  flake.modules.nixos.desktop-ollama = {
    lib,
    pkgs,
    ...
  }: let
    baseModel = "hf.co/outsourc-e/Qwen3.8-27B-Unleashed-GGUF:UD-Q3_K_XL";

    modelName = "qwen3.8-local";

    # Sampling values from the model card. The 13.2 GB weights leave little
    # VRAM, so context stays at 16k. num_predict covers the thinking tokens.
    modelfile = pkgs.writeText "qwen3.8-local-Modelfile" ''
      FROM ${baseModel}

      PARAMETER temperature 1.0
      PARAMETER top_k 20
      PARAMETER top_p 0.95
      PARAMETER min_p 0
      PARAMETER repeat_penalty 1.0
      PARAMETER num_ctx 16384
      PARAMETER num_predict 12288

      SYSTEM """
      ${lib.trim (builtins.readFile ./system-prompt.txt)}
      """
    '';
  in {
    systemd.services.ollama-custom-model.script = ''
      ollama pull ${lib.escapeShellArg baseModel}

      ollama create ${lib.escapeShellArg modelName} \
        --file ${modelfile}
    '';
  };
}

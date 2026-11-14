{
  flake.modules.nixos.desktop-ollama = {
    lib,
    pkgs,
    ...
  }: let
    baseModel = "hf.co/HauhauCS/Gemma4-12B-QAT-Uncensored-HauhauCS-Balanced:Q4_K_M";

    modelName = "gemma4-local";

    modelfile = pkgs.writeText "gemma4-local-Modelfile" ''
      FROM ${baseModel}

      PARAMETER temperature 0.6
      PARAMETER top_k 64
      PARAMETER top_p 0.9
      PARAMETER min_p 0.05
      PARAMETER repeat_penalty 1.1
      PARAMETER num_ctx 32768
      PARAMETER num_predict 2048

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

{
  flake.modules.nixos.desktop-comfyui = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.comfyui;

    modelRepository = "rectangleworm/PornMaster_Klein-9b";
    # Pinned commit, so a reboot cannot pull different weights. Change it
    # deliberately to update the model.
    modelRevision = "11d13345336b59105223ad96b1e2c1cd2470bdd9";

    modelManifest = pkgs.writeText "comfyui-flux-models.json" (builtins.toJSON {
      repository = modelRepository;
      revision = modelRevision;
      data_directory = cfg.dataDir;
      files = [
        {
          source = "unet/turbo/PornMaster_Flux2Klein_v4_Turbo_bf16.safetensors";
          destination = "models/diffusion_models/PornMaster_Flux2Klein_v4_Turbo_bf16.safetensors";
        }
        {
          source = "text_encoders/Qwen3-VL-8B-Q8_0.gguf";
          destination = "models/text_encoders/Qwen3-VL-8B-Q8_0.gguf";
        }
        {
          source = "vae/flux2-vae.safetensors";
          destination = "models/vae/flux2-vae.safetensors";
        }
      ];
    });

    checker = pkgs.writeShellScriptBin "comfyui-flux-check" ''
      exec ${pkgs.python3}/bin/python3 ${../../comfyui/check-comfyui.py} \
        --url http://127.0.0.1:${toString cfg.port} \
        --workflow ${./flux-klein-api.json}
    '';
  in {
    environment.systemPackages = [checker];
    environment.etc."comfyui/flux-klein-starter.json".source = ./flux-klein-starter.json;
    environment.etc."comfyui/flux-klein-edit.json".source = ./flux-klein-edit.json;
    environment.etc."comfyui/flux-klein-api.json".source = ./flux-klein-api.json;

    # ComfyUI can start while files download. Partial files end in .part and
    # are renamed only after their Hugging Face SHA-256 and size are verified.
    systemd.services.comfyui-flux-models = {
      description = "Download and verify the ComfyUI FLUX model components";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      environment = {
        PYTHONUNBUFFERED = "1";
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      serviceConfig = {
        Type = "exec";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "comfyui";
        StateDirectoryMode = "0750";
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${pkgs.python3}/bin/python3 ${../../comfyui/download-models.py} ${modelManifest}";
        Restart = "on-failure";
        RestartSec = "30s";
        UMask = "0027";
      };
    };

    # Use distinct, managed filenames; save your edits under a new name in the UI.
    systemd.services.comfyui.preStart = lib.mkAfter ''
      ${pkgs.coreutils}/bin/install -D -m 0644 \
        ${./flux-klein-starter.json} \
        ${lib.escapeShellArg "${cfg.dataDir}/user/default/workflows/flux-klein-starter.json"}
      ${pkgs.coreutils}/bin/install -D -m 0644 \
        ${./flux-klein-edit.json} \
        ${lib.escapeShellArg "${cfg.dataDir}/user/default/workflows/flux-klein-edit.json"}
    '';
  };
}

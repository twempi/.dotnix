{inputs, ...}: {
  flake.modules.nixos.desktop-comfyui-flux = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.comfyui;

    # This is the diffusion model, NOT the Qwen text encoder that Ollama pulled.
    modelRepository = "rectangleworm/PornMaster_Klein-9b";
    # Replace "main" with the resolved commit in model-receipt.json to pin weights.
    modelRevision = "main";

    modelManifest = pkgs.writeText "comfyui-flux-models.json" (builtins.toJSON {
      repository = modelRepository;
      revision = modelRevision;
      data_directory = cfg.dataDir;
      files = [
        {
          source = "unet/turbo/PornMaster_Flux2Klein_v4_Turbo_Q4_K.gguf";
          destination = "models/diffusion_models/PornMaster_Flux2Klein_v4_Turbo_Q4_K.gguf";
        }
        {
          source = "text_encoders/Qwen3-VL-8B-Q4_K_M.gguf";
          destination = "models/text_encoders/Qwen3-VL-8B-Q4_K_M.gguf";
        }
        {
          source = "vae/flux2-vae.safetensors";
          destination = "models/vae/flux2-vae.safetensors";
        }
      ];
    });

    checker = pkgs.writeShellScriptBin "comfyui-flux-check" ''
      exec ${pkgs.python3}/bin/python3 ${./check-comfyui.py} \
        --url http://127.0.0.1:${toString cfg.port} \
        --workflow ${./flux-klein-api.json}
    '';
  in {
    # This import supplies the options below and disables the nixpkgs module
    # with the same service name. Import this file through NixOS, not Home Manager.
    imports = [inputs.comfyui-nix.nixosModules.default];

    services.comfyui = {
      enable = true;
      gpuSupport = "cuda";
      listenAddress = "127.0.0.1";
      port = 8188;
      dataDir = "/var/lib/comfyui";
      openFirewall = false;

      # Includes the flake's pinned ComfyUI-GGUF custom node and dependencies.
      bundledCustomNodes = true;
      # Custom nodes come from the flake; no runtime installation is needed.
      enableManager = false;

      # Conservative starting point for a 16 GB GPU shared with the desktop.
      extraArgs = ["--lowvram"];
    };

    environment.systemPackages = [checker];
    environment.etc."comfyui/flux-klein-starter.json".source = ./flux-klein-starter.json;
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
        ExecStart = "${pkgs.python3}/bin/python3 ${./download-models.py} ${modelManifest}";
        Restart = "on-failure";
        RestartSec = "30s";
        UMask = "0027";
      };
    };

    # Use a distinct, managed filename; save your edits under a new name in the UI.
    systemd.services.comfyui.preStart = lib.mkAfter ''
      ${pkgs.coreutils}/bin/install -D -m 0644 \
        ${./flux-klein-starter.json} \
        ${lib.escapeShellArg "${cfg.dataDir}/user/default/workflows/flux-klein-starter.json"}
    '';
  };
}

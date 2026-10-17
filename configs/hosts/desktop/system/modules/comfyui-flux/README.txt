COMFYUI + FLUX ON NIXOS (RTX 4070 TI SUPER)

This folder is a NixOS module. Copy the WHOLE folder into your .dotnix
repository. Keep the Python and JSON files beside default.nix.
Do not import it through Home Manager.

1. ADD THE FLAKE INPUT

Add this to the existing inputs attribute set in your flake.nix:

  comfyui-nix.url = "github:utensils/comfyui-nix";

Keep this input's own nixpkgs lock initially. The package flake brings its
tested dependency set; there is no need to add nixpkgs.follows for this setup.

2. IMPORT THE FOLDER FROM YOUR DESKTOP NIXOS CONFIGURATION

In your existing NixOS configuration's imports, add the folder path:

  imports = [
    # Other existing imports...
    ./comfyui-flux
  ];

Adjust this relative path to match where you copied the folder. This module
imports inputs.comfyui-nix.nixosModules.default itself.

The module receives inputs through NixOS specialArgs. If your configuration
already uses inputs in other modules, it is probably already configured.
Otherwise, add/merge this into the existing nixpkgs.lib.nixosSystem call:

  specialArgs = { inherit inputs; };

The outputs function must bind inputs, e.g.:

  outputs = inputs@{ self, nixpkgs, ... }: { ... };

Do not replace your existing flake with the snippets above. Merge the input,
imports, and specialArgs into its current structure.

3. STAGE THE FILES AND REBUILD

From ~/.dotnix, stage the folder using its actual relative path:

  git add path/to/comfyui-flux
  nrs

Nix will add comfyui-nix to flake.lock. Stage flake.nix and flake.lock when
you commit your configuration. Home Manager does not manage this service.

4. WATCH THE MODEL DOWNLOAD

  journalctl -fu comfyui-flux-models.service

Wait for:

  ALL MODEL FILES VERIFIED AND READY.

The rebuild can finish before the model downloads. ComfyUI may initially show
empty model selectors. Partial downloads use .part names, resume on retry,
and are atomically installed after size and SHA-256 checks. A failed download
service retries after 30 seconds. Ctrl+C stops watching the log, not the service.

Progress is printed approximately every 10 seconds during each transfer.
Hash verification of a large file can take time without a progress line.

5. CHECK THE APPLICATION AND OPEN THE WORKFLOW

  systemctl status comfyui.service --no-pager
  comfyui-flux-check

Open http://localhost:8188 . Refresh after the download finishes. Load the
workflow called flux-klein-starter from ComfyUI's workflow browser. If it is
not listed, use Open/Load and select this accessible local file:

  /etc/comfyui/flux-klein-starter.json

The same file is included in this download. It has a neutral test prompt,
768 x 768 resolution, batch size 1, four sampling steps, Euler sampling, and
BasicGuider (CFG 1). It uses the V4 TURBO checkpoint, so no Turbo LoRA is needed.

Click Run/Queue to generate a test image. The first run also loads the weights
and can take longer. Save an edited workflow with a different name: the managed
flux-klein-starter copy is replaced when ComfyUI starts.

If you change resolution, change both EmptyFlux2LatentImage and Flux2Scheduler
to the same width/height. Start with 768 x 768; larger images require more VRAM.

MODEL FILES

Source repository: rectangleworm/PornMaster_Klein-9b

Diffusion model:
  unet/turbo/PornMaster_Flux2Klein_v4_Turbo_Q4_K.gguf
  -> /var/lib/comfyui/models/diffusion_models/

Text encoder:
  text_encoders/Qwen3-VL-8B-Q4_K_M.gguf
  -> /var/lib/comfyui/models/text_encoders/

VAE:
  vae/flux2-vae.safetensors
  -> /var/lib/comfyui/models/vae/

Outputs are stored under /var/lib/comfyui/output and can be saved/downloaded
from the browser. Model receipt: /var/lib/comfyui/model-receipt.json.

The app binds only to 127.0.0.1:8188. Your existing Ollama/Open WebUI services
can run alongside it, but a loaded chat model consumes the same GPU memory.
Before generating images, unload any model shown by `ollama ps`, for example:

  ollama stop gemma4-local

If another model is loaded, use its exact name from `ollama ps`.

DECLARATIVE CONFIGURATION AND MODEL PINNING

The Nix module declares the service, CUDA backend, nodes (via the flake), exact
model filenames, and starter workflow. The app and bundled nodes are pinned
by your flake.lock. Weights are downloaded at runtime into persistent storage.
No placeholder SHA-256 hashes are used.

On each provisioning run, modelRevision = "main" resolves to ONE concrete
Hugging Face commit. All three files come from that same commit and are
checked against the repository's LFS SHA-256 metadata. A receipt records it.
This checks download integrity; it does not independently audit the publisher.

To make future runs use identical weights, read the resolved revision:

  sudo cat /var/lib/comfyui/model-receipt.json

Then set modelRevision in default.nix to that resolved_revision commit SHA.
Rebuild with nrs. You may also provide any known full Hugging Face commit SHA
there before the initial download. With "main", future restarts/reboots may
resolve newer weights. This behavior is explicit rather than claiming that
flake.lock also pins external model weights.

There is no automatic deletion of other model files. Runtime downloads stay
outside the Nix store and do not inflate your Git repository.

TROUBLESHOOTING

  journalctl -u comfyui.service -b -n 80 --no-pager
  journalctl -u comfyui-flux-models.service -b -n 80 --no-pager
  sudo systemctl restart comfyui-flux-models.service

If the check reports a missing node, inspect ComfyUI's startup log for an
import error. If `flux2` is not a supported encoder type, or nodes such as
Flux2Scheduler/EmptyFlux2LatentImage are missing, the locked ComfyUI version
is too old for this workflow. Update the comfyui-nix input deliberately:

  nix flake update comfyui-nix
  nrs

If GPU memory is exhausted, unload Ollama models, keep batch size at 1, and
reduce both workflow dimensions together. --lowvram is already enabled.
Actual system RAM requirements and generation speed depend on resolution
and CPU offloading; this exact model has not been benchmarked here.

VALIDATION PERFORMED

The module's ComfyUI options were checked against utensils/comfyui-nix's
documentation. Model paths were checked against the publisher's model card.
Workflow link consistency and Python syntax were checked locally; transfer
logic was exercised against a local HTTP server, including interrupted/resumed
downloads and hash failures. The checker validates node/model selections
against your actual ComfyUI /object_info endpoint after installation.

This authoring environment has no Nix executable or NVIDIA GPU, so a NixOS
evaluation/build and actual image generation were not run here. The supplied
workflow is a newly authored starter graph, not a tested copy of the publisher's
example. Test the neutral prompt first; schema success alone does not prove
the selected Qwen encoder and checkpoint work together in the locked runtime.

REFERENCES

https://github.com/utensils/comfyui-nix
https://github.com/city96/ComfyUI-GGUF
https://docs.comfy.org/tutorials/flux/flux-2-klein
https://huggingface.co/rectangleworm/PornMaster_Klein-9b?not-for-all-audiences=true
https://github.com/Comfy-Org/workflow_templates/blob/main/blueprints/text_to_image_flux_2_dev.json

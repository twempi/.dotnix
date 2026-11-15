COMFYUI + FLUX ON NIXOS (RTX 4070 TI SUPER)

Files:
  ai/comfyui/default.nix                    the ComfyUI service (desktop-comfyui)
  ai/models/pornmaster-klein/default.nix   model download, workflows, checker
                                            (also desktop-comfyui)

The comfyui-nix flake input is in flake.nix and keeps its own nixpkgs lock.
desktop-comfyui is imported in configs/hosts/desktop/default.nix. Activate
with nrs. Home Manager does not manage this service.

1. WATCH THE MODEL DOWNLOAD

  journalctl -fu comfyui-flux-models.service

Wait for:

  ALL MODEL FILES VERIFIED AND READY.

The rebuild can finish before the model downloads. ComfyUI may initially show
empty model selectors. Partial downloads use .part names, resume on retry,
and are atomically installed after size and SHA-256 checks. A failed download
service retries after 30 seconds. Ctrl+C stops watching the log, not the service.

Progress is printed approximately every 10 seconds during each transfer.
Hash verification of a large file can take time without a progress line.

2. CHECK THE APPLICATION AND OPEN THE WORKFLOW

  systemctl status comfyui.service --no-pager
  comfyui-flux-check

Open http://localhost:8188 . Refresh after the download finishes. Load the
workflow called flux-klein-starter from ComfyUI's workflow browser. If it is
not listed, use Open/Load and select this accessible local file:

  /etc/comfyui/flux-klein-starter.json

For image editing, load flux-klein-edit (/etc/comfyui/flux-klein-edit.json).
It scales the reference to 2 megapixels and uses CFGGuider at CFG 1.5 with 8
steps and a zeroed negative (one of the publisher's documented settings). At
CFG 1 edits come out with glitchy, blocky artifacts; CFG 2 works but adds
visible contrast and saturation. The result is resized back to the original
image's resolution, though detail is limited to what 2 MP can hold.

Q8_0 diffusion GGUFs from this repository do not load: they quantize the
RMSNorm weights, which ComfyUI-GGUF does not dequantize (shape [136] vs [128]
error). The workflows therefore use the unquantized bf16 safetensors through
the core UNETLoader. At about 17 GB it does not fit in 16 GB of VRAM, so
ComfyUI offloads part of it to system RAM and generation is slower. Q6_K is
the largest GGUF that works if you need a faster, smaller model.

The same file is included in this download. It has a neutral test prompt,
768 x 768 resolution, batch size 1, four sampling steps, Euler sampling, and
BasicGuider (CFG 1). It uses the V4 TURBO checkpoint, so no Turbo LoRA is needed.

Click Run/Queue to generate a test image. The first run also loads the weights
and can take longer. Save an edited workflow with a different name: the managed
flux-klein-starter and flux-klein-edit copies are replaced when ComfyUI starts.

If you change resolution, change both EmptyFlux2LatentImage and Flux2Scheduler
to the same width/height. Start with 768 x 768; larger images require more VRAM.

MODEL FILES

Source repository: rectangleworm/PornMaster_Klein-9b

Diffusion model:
  unet/turbo/PornMaster_Flux2Klein_v4_Turbo_bf16.safetensors
  -> /var/lib/comfyui/models/diffusion_models/

Text encoder:
  text_encoders/Qwen3-VL-8B-Q8_0.gguf
  -> /var/lib/comfyui/models/text_encoders/

VAE:
  vae/flux2-vae.safetensors
  -> /var/lib/comfyui/models/vae/

Outputs are stored under /var/lib/comfyui/output and can be saved/downloaded
from the browser. Model receipt: /var/lib/comfyui/model-receipt.json.

The app binds only to 127.0.0.1:8188. Your existing Ollama/Open WebUI services
can run alongside it, but a loaded chat model consumes the same GPU memory.
Before generating images, unload any model shown by `ollama ps`, for example:

  ollama stop qwen3.8-local

If another model is loaded, use its exact name from `ollama ps`.

DECLARATIVE CONFIGURATION AND MODEL PINNING

The Nix module declares the service, CUDA backend, nodes (via the flake), exact
model filenames, and starter workflow. The app and bundled nodes are pinned
by your flake.lock. Weights are downloaded at runtime into persistent storage.
No placeholder SHA-256 hashes are used.

modelRevision in ai/models/pornmaster-klein/default.nix is a full Hugging
Face commit SHA. All three files come from that commit and are checked against
the repository's LFS SHA-256 metadata. A receipt records it. This checks
download integrity; it does not independently audit the publisher. To update
the weights, set modelRevision to a newer commit SHA and rebuild.

Changing filenames or revision downloads the new files but does not delete
the old ones from /var/lib/comfyui/models.

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
reduce both workflow dimensions together. If that is not enough, add
extraArgs = ["--lowvram"]; to services.comfyui (slower).
Actual system RAM requirements and generation speed depend on resolution
and CPU offloading; this exact model has not been benchmarked here.

VALIDATION PERFORMED

The desktop NixOS configuration builds with this module. Image generation has
not been run. The workflows are newly authored graphs, not tested copies of the
publisher's examples. Test the neutral prompt first; schema success alone does
not prove the selected Qwen encoder and checkpoint work together in the locked
runtime. The publisher's own workflows are in the model repository under
example_workflows/.

REFERENCES

https://github.com/utensils/comfyui-nix
https://github.com/city96/ComfyUI-GGUF
https://docs.comfy.org/tutorials/flux/flux-2-klein
https://huggingface.co/rectangleworm/PornMaster_Klein-9b?not-for-all-audiences=true
https://github.com/Comfy-Org/workflow_templates/blob/main/blueprints/text_to_image_flux_2_dev.json

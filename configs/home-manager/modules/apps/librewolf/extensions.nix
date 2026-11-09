{inputs, ...}: {
  flake.modules.homeManager.librewolf = {
    lib,
    pkgs,
    ...
  }: let
    mkXpi = import ./_mk-xpi.nix {inherit lib pkgs;};
    webStore = import ../helium/_extensions/web-store.nix {inherit lib pkgs inputs;};

    forceInstall = url: {
      install_url = url;
      installation_mode = "force_installed";
    };

    # Helium's Web Store extensions with an AMO build, keyed by gecko id.
    amoExtensions = {
      "languagetool-webextension@languagetool.org" = "languagetool";
      "{85860b32-02a8-431a-b2b1-40fbd64c9c69}" = "github-file-icons";
      "sponsorBlocker@ajay.app" = "sponsorblock";
      "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = "return-youtube-dislikes";
      "{74145f27-f039-47ce-a470-a662b129930a}" = "clearurls";
      "{3c6bf0cc-3ae2-42fb-9993-0d33104fdcaf}" = "youtube-addon";
      "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = "vimium-ff";
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
      "floccus@handmadeideas.org" = "floccus";
      "{7653b5cb-d76d-442f-a98f-f3c83a118cf4}" = "imagus-reborn";
      "{8927f234-4dd9-48b1-bf76-44a9e153eee0}" = "better-canvas";
      "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = "video-downloadhelper";
      "clipper@obsidian.md" = "web-clipper-obsidian";
    };

    # The rest have no matching AMO listing, so Helium's pinned CRX is repacked.
    repackedExtensionIds = [
      "eboaimjcbpkmciikmjpceacdacegnfao" # Polyratings
      "ilmdofdhpnhffldihboadndccenlnfll" # ChatGPT Exporter
      "bgpnjdahpmkaflfpbkdplndklnmghklp" # Auto Typer
      "odcnpipkhjegpefkfplmedhmkmmhmoko" # Jobright Autofill
      "alhgpfoeiimagjlnfekdhkjlkiomcapa" # Apollo.io
      inputs.twempi.lib.canvas-local-archive.extension.id
    ];

    localExtensions =
      lib.listToAttrs (map (id:
        lib.nameValuePair "${id}@helium-repack"
        (webStore.fetchExtension (lib.findFirst (ext: ext.id == id) null webStore.extensions)))
      repackedExtensionIds)
      // {
        "discord-to-vesktop@local" = import ../helium/_extensions/discord-to-vesktop.nix {inherit pkgs;};
      };
  in {
    programs.librewolf.policies.ExtensionSettings =
      lib.mapAttrs (_: slug: forceInstall "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi") amoExtensions
      // lib.mapAttrs (id: src: forceInstall "file://${mkXpi {inherit id src;}}") localExtensions;
  };
}

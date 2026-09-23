{
  lib,
  pkgs,
}: let
  extensions = [
    {
      # AI Grammar Checker & Paraphraser - LanguageTool
      id = "oldceeleldhonbafppcapldpdifcinji";
      hash = "sha256-UEVCv/S2Clfzp9mU6c8q/NjAqug5GU4EZnu5z8l/LJE=";
    }
    {
      # File Icons for GitHub and GitLab
      id = "ficfmibkjjnpogdcfhfokmihanoldbfe";
      hash = "sha256-r9RsPoGXx/dka1INM9KOddNl6ccHCjHHEqJmcjsUPYM=";
    }
    {
      # SponsorBlock for YouTube
      id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      hash = "sha256-nE5FE3Eo1jG8sT1KYjVl8JRbmAiyhN8IZObHsAIb0wY=";
    }
    {
      # Return YouTube Dislike
      id = "gebbhagfogifgggkldgodflihgfeippi";
      hash = "sha256-0ZO+7AY5dcy1AOXPtZ9sSPcj9Wl2RQkE9oOFZq7ESqM=";
    }
    {
      # ClearURLs
      id = "lckanjgmijmafbedllaakclkaicjfmnk";
      hash = "sha256-rMFzGyrQCJ85p93PDHIy7TU329AZuOjBvuzoeO1Yoxo=";
    }
    {
      # Improve YouTube
      id = "bnomihfieiccainjcjblhegjgglakjdd";
      hash = "sha256-xFEBWKB0ZPQ3myFJw9+RK2ohVloHvpA+acL1VK5fUJs=";
    }
    {
      # Vimium
      id = "dbepggeogbaibhgnhhndojpepiihcmeb";
      hash = "sha256-MZjCaqcZvkYt6lhQUPvtm4uAYo1X6oihE7q/UzTFUXw=";
    }
    {
      # Bitwarden Password Manager
      id = "nngceckbapebfimnlniiiahkandclblb";
      hash = "sha256-XOVs2Tvay8hQ13SHz+728BDu2mMyQ0JxUuUI6FZ1NaM=";
    }
    {
      # Floccus Bookmarks Sync
      id = "fnaicdffflnofjppbagibeoednhnbjhg";
      hash = "sha256-+/cyGI5sj6V9OitbBeOl/pkM//Vj/qACXpgkn8TETz0=";
    }
    {
      # Imagus Reborn
      id = "fcjmgeodgobggcppooncdagfkogfffdm";
      hash = "sha256-ioqkGne9PJUqoNV//PIfQlG3CIfGzhsXpJmS5Pt5bCM=";
    }
    {
      # Better Campus
      id = "cndibmoanboadcifjkjbdpjgfedanolh";
      hash = "sha256-sJi02k5DgLpwrsrQHqlvXdWu4tNW+WqFiMT0qbsmXvc=";
    }
    # Video DownloadHelper
    {
      id = "lmjnegcaeklhafolokijcfjliaokphfk";
      hash = "sha256-7nJNCJ4qvjzuUIgljdaPo7UnQZf9YNCyy2xBmq87e/w=";
    }
    # ChatGPT Exporter
    {
      id = "ilmdofdhpnhffldihboadndccenlnfll";
      hash = "sha256-InqXKKEblfVEehgnEjFYCjrzVnbr90djmzyROKH/NCA=";
    }
    # Polyratings Extension
    {
      id = "eboaimjcbpkmciikmjpceacdacegnfao";
      hash = "sha256-xXPE57buWkwYAG+V0K6LbErYQh8XoZUOYSrOCGzNndY=";
    }
    # Obsidian Web Clipper
    {
      id = "cnjifjpddelmedmihgijeibhnjfabmlf";
      hash = "sha256-4BLH0QvZj3yL4tqv/WBdZKij1Vye4p26oy4b9oB25/M=";
    }
    # Auto Typer
    {
      id = "bgpnjdahpmkaflfpbkdplndklnmghklp";
      hash = "sha256-L4ts/TG52HaHah9ZZBnVKjT6+h8tUY9C/eYeZcx6cMM=";
    }
    # Jobright Autofill
    {
      id = "odcnpipkhjegpefkfplmedhmkmmhmoko";
      hash = "sha256-PtfEgRIRT3Md+PPFyc5s4TGDxJw/P7/haXkYWZj2KD4=";
    }
  ];

  fetchExtension = {
    id,
    hash,
  }: let
    os =
      if pkgs.stdenv.hostPlatform.isDarwin
      then "mac"
      else "linux";
    arch =
      if pkgs.stdenv.hostPlatform.isAarch64
      then "arm64"
      else "x64";
    os_arch =
      if pkgs.stdenv.hostPlatform.isDarwin
      then "arm64"
      else "x86_64";
  in
    pkgs.fetchurl {
      name = "${id}.crx";
      url = "https://clients2.google.com/service/update2/crx?response=redirect&os=${os}&arch=${arch}&os_arch=${os_arch}&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=stable&prodversion=120.0.0.0&acceptformat=crx3&x=id%3D${id}%26installsource%3Dondemand%26uc";
      inherit hash;
    };

  externalExtensionJson = {
    id,
    hash,
  }:
    pkgs.runCommand "helium-external-extension-${id}.json" {
      nativeBuildInputs = [pkgs.jq pkgs.unzip];
      crx = fetchExtension {inherit id hash;};
    } ''
      manifest="$(unzip -p "$crx" manifest.json 2>/dev/null || true)"
      version="$(printf '%s' "$manifest" | jq -r .version)"
      test -n "$version"
      test "$version" != "null"

      jq -n \
        --arg crx "$crx" \
        --arg version "$version" \
        '{ external_crx: $crx, external_version: $version }' > "$out"
    '';
in {
  configFiles = lib.listToAttrs (
    map (extension: {
      name = "net.imput.helium/External Extensions/${extension.id}.json";
      value.source = externalExtensionJson extension;
    })
    extensions
  );
}

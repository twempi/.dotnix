{pkgs}:
pkgs.runCommand "helium-discord-to-vesktop-extension" {} ''
  mkdir -p "$out"

  cat > "$out/manifest.json" <<'EOF'
  {
    "manifest_version": 3,
    "name": "Open Discord links in Vesktop",
    "version": "1.0.0",
    "description": "Redirect Discord channel and invite links to Vesktop.",
    "content_scripts": [
      {
        "matches": [
          "*://discord.com/channels/*",
          "*://discord.com/invite/*",
          "*://discord.gg/*"
        ],
        "js": ["redirect.js"],
        "run_at": "document_start"
      }
    ]
  }
  EOF

  cat > "$out/redirect.js" <<'EOF'
  const url = new URL(location.href);
  const path = url.hostname === "discord.gg" ? `/invite''${url.pathname}` : url.pathname;

  location.replace(`discord://-''${path}''${url.search}''${url.hash}`);
  EOF
''

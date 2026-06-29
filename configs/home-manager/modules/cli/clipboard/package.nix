{
  coreutils,
  symlinkJoin,
  wl-clipboard,
  writeShellApplication,
  xclip,
  xsel,
}: let
  copy = writeShellApplication {
    name = "dotnix-copy";
    runtimeInputs = [
      coreutils
      wl-clipboard
      xclip
      xsel
    ];
    text = ''
      tmp="$(mktemp)"
      trap 'rm -f "$tmp"' EXIT

      cat >"$tmp"

      if [ -n "''${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
        if wl-copy --type text/plain <"$tmp"; then
          exit 0
        fi
      fi

      if [ -n "''${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
        if xclip -selection clipboard -in <"$tmp"; then
          exit 0
        fi
      fi

      if [ -n "''${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
        if xsel --clipboard --input <"$tmp"; then
          exit 0
        fi
      fi

      encoded="$(base64 -w 0 <"$tmp")"
      if printf '\033]52;c;%s\a' "$encoded" 2>/dev/null >/dev/tty; then
        exit 0
      fi

      exit 1
    '';
  };

  paste = writeShellApplication {
    name = "dotnix-paste";
    runtimeInputs = [
      wl-clipboard
      xclip
      xsel
    ];
    text = ''
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then
        if wl-paste --no-newline; then
          exit 0
        fi
      fi

      if [ -n "''${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
        if xclip -selection clipboard -out; then
          exit 0
        fi
      fi

      if [ -n "''${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
        if xsel --clipboard --output; then
          exit 0
        fi
      fi

      exit 0
    '';
  };
in
  symlinkJoin {
    name = "dotnix-clipboard";
    paths = [
      copy
      paste
    ];
  }

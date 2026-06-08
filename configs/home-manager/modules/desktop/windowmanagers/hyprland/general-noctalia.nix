{
  pkgs,
  lib,
  ...
}: let
  lua = lib.generators.mkLuaInline;
  toLua = lib.generators.toLua {};
  exec = command: "  hl.exec_cmd(${toLua command})";
  execWithRules = command: rules: "  hl.exec_cmd(${toLua command}, ${toLua rules})";
  autostart = [
    (exec "uwsm app -- awww-daemon")
    (exec "uwsm app -- ${pkgs.openrgb}/bin/openrgb --profile ~/.config/OpenRGB/black.orp")
    (exec "${pkgs.systemd}/bin/systemctl --user stop swaync.service || true")
    (exec "${pkgs.procps}/bin/pkill waybar || true")
    (exec "uwsm app -- noctalia --daemon")
    (execWithRules "uwsm app -- spotify" {workspace = "9 silent";})
    (execWithRules "uwsm app -- obsidian" {workspace = "10 silent";})
    (exec "sleep 4 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1")
    (exec "sleep 5 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1")
    (exec "${pkgs.cliphist}/bin/cliphist wipe")
    (exec "uwsm app -- ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store")
  ];
in {
  imports = [
    ./general.nix
  ];

  wayland.windowManager.hyprland.settings.on = lib.mkForce {
    _args = [
      "hyprland.start"
      (lua ''
        function()
        ${lib.concatStringsSep "\n" autostart}
        end
      '')
    ];
  };
}

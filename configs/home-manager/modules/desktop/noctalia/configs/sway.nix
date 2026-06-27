{...}: {
  bar.default = {
    border_width = 0;
    capsule = false;
    center = [];
    end = [
      "tray"
      "network"
      "disk"
      "cpu"
      "brightness"
      "ram"
      "volume"
      "battery"
      "clock"
      "notifications"
    ];
    font_family = "IosevkaTerm Nerd Font Propo";
    font_weight = 900;
    margin_edge = 0;
    margin_ends = 0;
    padding = 6;
    radius = 0;
    shadow = false;
    start = ["workspaces"];
    thickness = 24;
    widget_spacing = 4;
  };

  widget = {
    battery = {
      display_mode = "glyph";
      show_label = true;
      warning_color = "error";
    };

    brightness = {
      scroll_step = 5;
      show_label = true;
    };

    clock = {
      format = "{:%a %d | %I:%M %p}";
    };

    cpu = {
      display = "text";
      glyph = "cpu";
      show_label = true;
      stat = "cpu_usage";
      type = "sysmon";
    };

    disk = {
      display = "text";
      glyph = "server";
      path = "/";
      show_label = true;
      stat = "disk_pct";
      type = "sysmon";
    };

    network = {
      display = "text";
      glyph = "download";
      show_label = true;
      stat = "net_rx";
      type = "sysmon";
    };

    notifications = {
      hide_when_no_unread = true;
    };

    ram = {
      display = "text";
      glyph = "memory";
      show_label = true;
      stat = "ram_used";
      type = "sysmon";
    };

    tray = {
      hidden = [
        "blueman"
        "nm-applet"
        "pasystray"
      ];
    };

    volume = {
      device = "output";
      mute_color = "error";
      scroll_step = 5;
      show_label = true;
      type = "volume";
    };

    workspaces = {
      active_pill_size = 1.3;
      display = "id";
      empty_color = "outline";
      focused_color = "primary";
      hide_when_empty = false;
      inactive_pill_size = 1.0;
      labels_only_when_occupied = false;
      max_label_chars = 2;
      minimal = false;
      occupied_color = "secondary";
      pill_scale = 0.65;
      type = "workspaces";
    };
  };
}

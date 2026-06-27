{...}: {
  bar.default = {
    border_width = 1;
    capsule = true;
    capsule_border = "outline";
    capsule_fill = "surface_variant";
    capsule_padding = 8;
    capsule_radius = 0;
    center = [];
    end = [
      "network"
      "brightness"
      "cpu"
      "ram"
      "volume"
      "battery"
      "clock"
    ];
    font_family = "IosevkaTerm Nerd Font Propo";
    font_weight = 700;
    margin_edge = 4;
    margin_ends = 4;
    padding = 6;
    radius = 0;
    shadow = false;
    start = ["workspaces"];
    thickness = 26;
    widget_spacing = 6;
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
      format = "{:%a %d %b  %H:%M}";
      tooltip_format = "{:%A, %d %B %Y}";
    };

    cpu = {
      display = "text";
      glyph = "cpu";
      show_label = true;
      stat = "cpu_usage";
      type = "sysmon";
    };

    network = {
      show_label = true;
      type = "network";
    };

    ram = {
      display = "text";
      glyph = "memory";
      show_label = true;
      stat = "ram_pct";
      type = "sysmon";
    };

    volume = {
      device = "output";
      mute_color = "error";
      scroll_step = 5;
      show_label = true;
      type = "volume";
    };

    workspaces = {
      active_pill_size = 1.4;
      display = "id";
      empty_color = "outline";
      focused_color = "primary";
      hide_when_empty = true;
      inactive_pill_size = 1.0;
      labels_only_when_occupied = false;
      max_label_chars = 2;
      minimal = false;
      occupied_color = "secondary";
      pill_scale = 0.7;
      type = "workspaces";
    };
  };
}

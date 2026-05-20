{
  services.swaync.settings = {
    # --- Position / layers / CSS priority ---
    positionX = "right";
    positionY = "top";

    cssPriority = "user";

    layer = "overlay";
    control-center-layer = "top";
    layer-shell = true;
    layer-shell-cover-screen = true;

    # --- Control center geometry / margins ---
    control-center-width = 400;
    control-center-height = 900;

    control-center-margin-top = 10;
    control-center-margin-bottom = 10;
    control-center-margin-right = 10;
    control-center-margin-left = 0;

    # --- Notification window geometry ---
    notification-window-width = 380;
    notification-icon-size = 50;
    notification-body-image-height = 200;
    notification-body-image-width = 200;

    # --- Timeouts ---
    timeout = 5;
    timeout-low = 3;
    timeout-critical = 0;

    # --- Behavior / misc ---
    fit-to-screen = false;
    keyboard-shortcuts = true;
    image-visibility = "when-available";
    transition-time = 200;
    hide-on-clear = false;
    hide-on-action = true;
    text-empty = "No Notifications";
    script-fail-notify = true;
    relative-timestamps = true;
    notification-2fa-action = true;
    notification-inline-replies = false;

    # Example script kept from your original config (optional)
    scripts = {
      example-script = {
        exec = "echo 'Do something...'";
        urgency = "Normal";
      };
    };

    # --- Notification visibility rules (from JSON) ---
    notification-visibility = {
      example-name = {
        state = "muted";
        urgency = "Low";
        app-name = "Spotify";
      };
    };

    # --- Widgets (order matches your JSON config) ---
    widgets = [
      "buttons-grid"
      "mpris"
      "volume"
      "backlight"
      "dnd"
      "title"
      "notifications"
    ];

    widget-config = {
      # MPRIS widget
      mpris = {
        image-size = 60;
        image-radius = 0;
        # you had a blacklist in your old config; you can re-add if you want:
        # blacklist = [ "Spotify" "playerctld" ];
      };

      # Volume widget
      volume = {
        label = "  󰕾 ";
        expand-button-label = " ";
        collapse-button-label = " ";
        show-per-app = true;
        show-per-app-icon = false;
        show-per-app-label = true;
      };

      # Backlight widget
      backlight = {
        label = " 󰃟 ";
      };

      # DND widget
      dnd = {
        text = "Do Not Disturb";
      };

      # Title widget
      title = {
        text = "Notifications Center";
        clear-all-button = true;
        button-text = " 󰆴 ";
      };

      buttons-grid = {
        actions = [
          # wlsunset toggle (replaces Wi-Fi)
          {
            label = "󰖔"; # pick any icon you like
            type = "toggle";
            active = true;

            # Run your toggle script (recommended) OR inline command below
            command = "sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && wlsunset -T 4001 || killall wlsunset 2>/dev/null || true'";

            # Reflect current state in UI
            update-command = "sh -c 'pidof wlsunset >/dev/null && echo true || echo false'";
          }

          # Bluetooth toggle
          {
            label = "";
            type = "toggle";
            active = true;
            command = "sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && rfkill unblock bluetooth || rfkill block bluetooth'";
            update-command = "sh -c 'rfkill list bluetooth | grep -q \"Soft blocked: no\" && echo true || echo false'";
          }

          # Mic mute toggle
          {
            label = " ";
            type = "toggle";
            active = false;
            command = "sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && pactl set-source-mute @DEFAULT_SOURCE@ 1 || pactl set-source-mute @DEFAULT_SOURCE@ 0'";
            update-command = "sh -c '[[ $(pactl get-source-mute @DEFAULT_SOURCE@) == *yes* ]] && echo true || echo false'";
          }

          # Speaker mute toggle
          {
            label = " ";
            type = "toggle";
            active = false;
            command = "sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && pactl set-sink-mute @DEFAULT_SINK@ 1 || pactl set-sink-mute @DEFAULT_SINK@ 0'";
            update-command = "sh -c '[[ $(pactl get-sink-mute @DEFAULT_SINK@) == *yes* ]] && echo true || echo false'";
          }
        ];
      };
    };
  };
}

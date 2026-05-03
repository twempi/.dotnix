#!/usr/bin/env bash

# Kill and restart Waybar and SwayNC
pkill waybar
pkill swaync

# Optional: Kill any currently running Rofi instances
pkill rofi

# Reload Hyprland configuration
swaymsg reload

# Restart SwayNC and Waybar
swaync &
waybar -c ~/.config/waybar/sway.jsonc -s ~/.config/waybar/sway.css&

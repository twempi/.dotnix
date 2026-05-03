#!/usr/bin/env bash

# Kill and restart Waybar and SwayNC
pkill waybar
pkill swaync

# Optional: Kill any currently running Rofi instances
pkill rofi

# Reload Hyprland configuration
niri msg reload

# Restart SwayNC and Waybar
swaync &
waybar -c ~/.config/waybar/niri.jsonc -s ~/.config/waybar/niri.css&

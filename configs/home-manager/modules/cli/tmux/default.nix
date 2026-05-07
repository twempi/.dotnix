{
  stylix.targets.tmux.enable = true;

  programs.tmux = {
    enable = true;

    # Core behavior
    prefix = "C-a";
    baseIndex = 1;
    keyMode = "vi";
    escapeTime = 0;
    focusEvents = true;
    mouse = true;
    historyLimit = 10000;

    # Better TERM inside tmux
    terminal = "tmux-256color";

    # Home Manager can generate these vi-style pane binds:
    # prefix + h/j/k/l to move panes
    # prefix + H/J/K/L to resize panes
    customPaneNavigationAndResize = true;
    resizeAmount = 1;

    extraConfig = ''
      set -as terminal-features ",*:RGB"

      # Status bar
      set-option -g status-position top

      # Simple binds
      bind-key q kill-pane
      bind-key v copy-mode

      # Rename window/session
      bind-key r command-prompt -I "#W" "rename-window -- '%%'"
      bind-key R command-prompt -I "#S" "rename-session -- '%%'"

      # Optional: switch panes without prefix.
      # Comment these out if they interfere with shell/editor shortcuts.
      bind-key -n C-h select-pane -L
      bind-key -n C-j select-pane -D
      bind-key -n C-k select-pane -U
      bind-key -n C-l select-pane -R

      # Split panes with prefix + i/o
      unbind-key '"'
      unbind-key %
      bind-key i split-window -h
      bind-key o split-window -v
    '';
  };
}

{
  stylix.targets.ghostty.enable = false;

  programs.ghostty = {
    enable = true;

    settings = {
      font-family = "Geist Mono";
      font-size = 12;

      background-opacity = 0.8;
      background-blur = true;

      window-decoration = "auto";
      window-padding-balance = true;
      window-padding-x = 10;
      window-padding-y = 10;
      window-inherit-working-directory = false;
      confirm-close-surface = false;

      # startup / launch behavior
      gtk-single-instance = true;
      quit-after-last-window-closed = false;

      keybind = [
        "ctrl+shift+k=new_split:up"
        "ctrl+shift+j=new_split:down"
        "ctrl+shift+l=new_split:right"
        "ctrl+shift+h=new_split:left"
        "ctrl+shift+n=new_tab"
      ];
    };

    clearDefaultKeybinds = false;
    installVimSyntax = true;
    installBatSyntax = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}

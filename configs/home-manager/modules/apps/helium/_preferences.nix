{
  bookmark_bar = {
    show_apps_shortcut = false;
    show_on_all_tabs = true;
    show_tab_groups = false;
  };

  homepage = "chrome://newtab/";
  homepage_is_newtabpage = true;

  session = {
    restore_on_startup = 5;
  };

  vertical_tabs = {
    collapsed_state = true;
    enabled = true;
    uncollapsed_width = 200;
  };

  protocol_handler.allowed_origin_protocol_pairs = {
    "https://discord.com".discord = true;
    "https://discord.gg".discord = true;
  };
}

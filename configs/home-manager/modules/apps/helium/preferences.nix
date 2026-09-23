{homePage}: {
  browser = {
    show_home_button = false;
  };

  bookmark_bar = {
    show_apps_shortcut = false;
    show_managed_bookmarks = true;
    show_on_all_tabs = true;
    show_tab_groups = false;
  };

  homepage = homePage;
  homepage_is_newtabpage = false;

  session = {
    restore_on_startup = 5;
    startup_urls = [];
  };

  vertical_tabs = {
    collapsed_state = true;
    enabled = true;
    uncollapsed_width = 200;
  };

  autofill = {
    credit_card_enabled = false;
    profile_enabled = false;
  };

  credentials_enable_service = true;

  profile = {
    password_manager_enabled = false;
  };

  protocol_handler.allowed_origin_protocol_pairs = {
    "https://discord.com".discord = true;
    "https://discord.gg".discord = true;
  };
}

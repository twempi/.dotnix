mod bar;
mod lock;
mod menu;
mod notifications;
mod osd;
mod panel;
mod tray;
mod ui;

use amane::App;

// waybar, rofi and swaync's looks; popups are added last so they draw on top
pub fn app() -> App {
    App::new()
        .font(ui::MENU_FONT)
        .window_per_monitor(bar::view)
        .window_per_monitor(tray::tip_view)
        .window_per_monitor(notifications::popups_view)
        .window_per_monitor(panel::view)
        .window_per_monitor(tray::menu_view)
        .window_per_monitor(menu::view)
        .window_per_monitor(osd::view)
        .lock(lock::view)
}

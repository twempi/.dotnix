mod bar;
mod icons;
mod lock;
mod menu;
mod notifications;
mod osd;
mod panel;
mod stats;
mod theme;
mod tray;
mod ui;

use amane::App;

// replaces waybar, rofi and swaync on sway; popups are added last so they draw on top
fn main() {
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
        .ipc("launcher", menu::launcher)
        .ipc("menu", menu::dmenu)
        .ipc("notifications", notifications::toggle)
        .ipc("lock", lock::lock)
        .run();
}

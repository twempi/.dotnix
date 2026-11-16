mod logic;
mod looks;

// replaces waybar, rofi and swaync on sway, and noctalia on hyprland, each with its own look
fn main() {
    let look = if logic::compositor::hyprland() {
        looks::hyprland::app()
    } else {
        looks::sway::app()
    };

    look.ipc("launcher", logic::menu::launcher)
        .ipc("menu", logic::menu::dmenu)
        .ipc("notifications", logic::notifications::toggle)
        .ipc("lock", logic::lock::lock)
        .run();
}

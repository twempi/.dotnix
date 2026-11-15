mod logic;
mod looks;

// replaces waybar, rofi and swaync on sway
fn main() {
    looks::sway::app()
        .ipc("launcher", logic::menu::launcher)
        .ipc("menu", logic::menu::dmenu)
        .ipc("notifications", logic::notifications::toggle)
        .ipc("lock", logic::lock::lock)
        .run();
}

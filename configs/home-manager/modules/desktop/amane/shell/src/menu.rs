use std::collections::{HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::io::Write as _;
use std::os::unix::fs::OpenOptionsExt;
use std::path::{Path, PathBuf};
use std::time::Duration;

use amane::{
    Align, Center, Color, Column, Image, Key, LayerWindow, Monitor, Padding, Parent,
    Pointer, Rectangle, Row, Scroll, Service, Start, TextInput, Weight, Widget,
};

use crate::icons::data_dirs;
use crate::theme::{Theme, home};
use crate::ui::{self, MENU_FONT, MENU_TEXT, Placement};

const INPUT: &str = "picker";

// the rofi theme files this replaces: config.rasi, powermenu.rasi, wallpaper.rasi
#[derive(Clone, Copy, PartialEq, Default)]
enum Style {
    #[default]
    List,
    Power,
    Grid,
}

#[derive(Clone, Default)]
struct Entry {
    text: String,
    detail: String,
    icon: Option<PathBuf>,
    search: String,
}

#[derive(Default)]
enum Purpose {
    #[default]
    Closed,
    Launcher,
    // a script waiting on this fifo for "exit-code\nselection\n"
    Dmenu(PathBuf),
}

// rofi: one picker at a time, either the drun launcher or a -dmenu list
#[derive(Default)]
pub struct Picker {
    purpose: Purpose,
    style: Style,
    monitor: String,
    prompt: String,
    message: String,
    entries: Vec<Entry>,
    launch: Vec<String>,
    query: String,
    shown: Vec<usize>,
    selected: usize,
    offset: usize,
    // rofi's -kb-custom-N keys, which exit with 10 + N - 1
    keys: Vec<(char, i32)>,
    // the emoji picker asks for an outline emoji font, amane can't draw color ones
    font: String,
}

impl Service for Picker {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

impl Picker {
    fn open(&self) -> bool {
        !matches!(self.purpose, Purpose::Closed)
    }

    fn columns(&self) -> usize {
        if self.style == Style::Grid { 9 } else { 1 }
    }

    // rofi's listview lines: 12, 5 for the power menu, 3 rows of 9 for wallpapers
    fn page(&self) -> usize {
        match self.style {
            Style::List => 12,
            Style::Power => 5,
            Style::Grid => 27,
        }
    }

    fn filter(&mut self) {
        let tokens: Vec<String> = self
            .query
            .to_lowercase()
            .split_whitespace()
            .map(String::from)
            .collect();

        // every word has to match somewhere, like rofi's default matching
        self.shown = (0..self.entries.len())
            .filter(|&index| tokens.iter().all(|token| self.entries[index].search.contains(token)))
            .collect();

        self.selected = 0;
        self.offset = 0;
    }

    fn select(&mut self, selected: usize) {
        if self.shown.is_empty() {
            return;
        }

        self.selected = selected.min(self.shown.len() - 1);

        let columns = self.columns();
        let page = self.page();

        if self.selected < self.offset {
            self.offset = self.selected / columns * columns;
        } else if self.selected >= self.offset + page {
            self.offset = (self.selected / columns + 1) * columns - page;
        }
    }

    fn step(&mut self, delta: isize) {
        if self.shown.is_empty() {
            return;
        }

        let count = self.shown.len() as isize;

        // rofi's cycle: true
        let next = (self.selected as isize + delta).rem_euclid(count);

        self.select(next as usize);
    }
}

fn open(picker: Picker) {
    TextInput::set_text(INPUT, "");

    let mut picker = picker;
    picker.monitor = ui::focused_output();
    picker.filter();

    let previous = std::mem::replace(&mut *Picker::write(), picker);

    // a script whose menu was replaced gets the same answer as Escape
    if let Purpose::Dmenu(fifo) = previous.purpose {
        answer(&fifo, 1, "");
    }
}

pub fn launcher(_: &[String]) -> String {
    // the launcher keybind closes an open launcher again
    if matches!(Picker::read().purpose, Purpose::Launcher) {
        close(1, String::new());
        return String::from("closed");
    }

    let apps = Desktop::read().apps.clone();
    let history = history();

    let mut apps: Vec<_> = apps.into_iter().collect();

    // rofi drun lists the most launched programs first
    apps.sort_by_cached_key(|app| (std::cmp::Reverse(history.get(&app.id).copied().unwrap_or(0)), app.name.to_lowercase()));

    let picker = Picker {
        purpose: Purpose::Launcher,
        prompt: String::from("\u{f002}"),
        entries: apps
            .iter()
            .map(|app| Entry {
                text: app.name.clone(),
                detail: app.generic.clone(),
                icon: None,
                search: app.search.clone(),
            })
            .collect(),
        launch: apps.iter().map(|app| app.id.clone()).collect(),
        ..Picker::default()
    };

    open(picker);

    String::from("opened")
}

/*
 * `amane ipc call menu <dir>`: the amane-dmenu script leaves items, prompt, mesg,
 * keys and theme in the folder and waits on its fifo for the answer
 */
pub fn dmenu(arguments: &[String]) -> String {
    let Some(dir) = arguments.first().map(PathBuf::from) else {
        return String::from("usage: menu <dir>");
    };

    let read = |name: &str| fs::read_to_string(dir.join(name)).unwrap_or_default();

    let style = match read("theme").trim() {
        "power" => Style::Power,
        "wallpaper" => Style::Grid,
        _ => Style::List,
    };

    let keys = read("keys")
        .lines()
        .filter_map(|line| {
            let (number, key) = line.split_once(' ')?;
            let number: i32 = number.parse().ok()?;
            Some((key.chars().next()?, 9 + number))
        })
        .collect();

    let picker = Picker {
        purpose: Purpose::Dmenu(dir.join("result")),
        style,
        prompt: read("prompt").trim_end_matches('\n').to_string(),
        message: read("mesg").trim_end_matches('\n').to_string(),
        entries: read("items").lines().map(parse_row).collect(),
        keys,
        font: read("font").trim().to_string(),
        ..Picker::default()
    };

    open(picker);

    String::from("opened")
}

// rofi's row options: "text\0icon\x1f/path/to.png"
fn parse_row(line: &str) -> Entry {
    let (text, options) = line.split_once('\0').unwrap_or((line, ""));

    let mut icon = None;
    let mut parts = options.split('\x1f');

    while let (Some(key), Some(value)) = (parts.next(), parts.next()) {
        if key == "icon" {
            icon = Some(PathBuf::from(value));
        }
    }

    Entry {
        text: text.to_string(),
        detail: String::new(),
        icon,
        search: text.to_lowercase(),
    }
}

fn answer(fifo: &Path, code: i32, text: &str) {
    // non-blocking, so a script that already went away can't freeze the shell
    let file = OpenOptions::new()
        .write(true)
        .custom_flags(libc::O_NONBLOCK)
        .open(fifo);

    if let Ok(mut file) = file {
        let _ = write!(file, "{code}\n{text}\n");
    }
}

fn close(code: i32, text: String) {
    let picker = std::mem::take(&mut *Picker::write());

    if let Purpose::Dmenu(fifo) = picker.purpose {
        answer(&fifo, code, &text);
    }
}

fn dismiss() {
    close(1, String::new());
}

// Enter: the selected entry, or what was typed when nothing matches
fn accept(code: i32) {
    let (chosen, typed, launch) = {
        let picker = Picker::read();

        let index = picker.shown.get(picker.selected).copied();

        (
            index.map(|index| picker.entries[index].text.clone()),
            picker.query.clone(),
            index.and_then(|index| picker.launch.get(index).cloned()),
        )
    };

    if let Some(id) = launch {
        close(code, String::new());
        launch_app(&id);
        return;
    }

    if matches!(Picker::read().purpose, Purpose::Launcher) {
        return;
    }

    close(code, chosen.unwrap_or(typed));
}

fn picked(index: usize) {
    Picker::write().select(index);
    accept(0);
}

fn key(key: Key) {
    let (columns, keys) = {
        let picker = Picker::read();
        (picker.columns() as isize, picker.keys.clone())
    };

    match key {
        Key::Escape => dismiss(),
        Key::Enter => accept(0),
        Key::Down => Picker::write().step(columns),
        Key::Up => Picker::write().step(-columns),
        Key::Tab | Key::Right => Picker::write().step(1),
        Key::Left => Picker::write().step(-1),
        Key::Home => Picker::write().select(0),
        Key::End => Picker::write().select(usize::MAX),
        Key::Character(letter) => {
            if let Some((_, code)) = keys.iter().find(|(wanted, _)| *wanted == letter) {
                accept(*code);
            }
        }
        _ => {}
    }
}

fn scrolled(scroll: Scroll) {
    let columns = Picker::read().columns() as isize;

    Picker::write().step(if scroll.y > 0.0 { columns } else { -columns });
}

fn typed(text: String) {
    let mut picker = Picker::write();

    picker.query = text;
    picker.filter();
}

fn submitted(_: String) {
    accept(0);
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    let picker = Picker::read();
    let theme = Theme::read();
    let base = theme.base;

    // read here so the .desktop scan starts with the shell, not on the first launch
    let _desktop = Desktop::read();

    let visible = picker.open() && ui::shown_on(&picker.monitor, monitor);

    let (width, gap, padding, element_padding): (f32, f32, f32, f32) = match picker.style {
        Style::List => (600.0, 0.0, 5.0, 5.0),
        Style::Power => (350.0, 5.0, 8.0, 8.0),
        Style::Grid => (1000.0, 5.0, 5.0, 5.0),
    };

    let inner = width - padding * 2.0;
    let row_height = ui::height_of(&ui::text("A", MENU_TEXT, MENU_FONT)) + element_padding * 2.0;

    let mut sections: Vec<Box<dyn Widget>> = vec![Box::new(input_bar(&picker, inner, &base))];
    let mut height = ui::height_of(sections[0].as_ref());

    if !picker.message.is_empty() {
        let message = Rectangle::new()
            .width(inner)
            .height(row_height)
            .fill(base[1])
            .padding(element_padding)
            .align_child(Start, Center)
            .child(ui::text(&picker.message, MENU_TEXT, MENU_FONT).color(base[5]).elide());

        height += row_height + gap.max(5.0);
        sections.push(Box::new(message));
    }

    let visible_entries: Vec<usize> = picker
        .shown
        .iter()
        .skip(picker.offset)
        .take(picker.page())
        .copied()
        .collect();

    let list: Box<dyn Widget> = if picker.style == Style::Grid {
        let cell = (inner - 8.0 * gap) / 9.0;
        let cell_height = cell + row_height;

        let rows: Vec<Box<dyn Widget>> = visible_entries
            .chunks(9)
            .enumerate()
            .map(|(row, chunk)| {
                let cells: Vec<Box<dyn Widget>> = chunk
                    .iter()
                    .enumerate()
                    .map(|(column, &index)| {
                        let position = picker.offset + row * 9 + column;
                        Box::new(grid_cell(&picker.entries[index], position, position == picker.selected, cell, cell_height, &base))
                            as Box<dyn Widget>
                    })
                    .collect();
                Box::new(Row::new(cells).gap(gap)) as Box<dyn Widget>
            })
            .collect();

        height += 3.0 * cell_height + 2.0 * gap + gap;

        Box::new(Column::new(rows).gap(gap).height(3.0 * cell_height + 2.0 * gap))
    } else {
        let rows: Vec<Box<dyn Widget>> = visible_entries
            .iter()
            .enumerate()
            .map(|(row, &index)| {
                let position = picker.offset + row;
                Box::new(list_row(&picker.entries[index], &picker.font, position, position == picker.selected, inner, row_height, element_padding, &base))
                    as Box<dyn Widget>
            })
            .collect();

        // rofi's dynamic: true, the list shrinks to fit few entries
        let count = rows.len().max(1) as f32;
        height += count * row_height + (count - 1.0) * gap + gap.max(5.0);

        Box::new(Column::new(rows).gap(gap))
    };

    sections.push(list);

    let panel = ui::swallow_clicks(
        Rectangle::new()
            .width(width)
            .height(height + padding * 2.0 + 2.0)
            .fill(base[0])
            .border(1.0, base[0x0A])
            .padding(padding + 1.0)
            .on_scroll(scrolled)
            .child(Column::new(sections).gap(gap.max(5.0))),
    );

    ui::overlay("amane-menu", visible, Placement::center(), dismiss, key, panel)
}

fn input_bar(picker: &Picker, width: f32, base: &[Color; 16]) -> Rectangle {
    let line = ui::height_of(&ui::text("A", MENU_TEXT, MENU_FONT));

    if picker.style == Style::Power {
        // powermenu.rasi: a red power glyph box, then the hostname on the accent color
        let glyph = Rectangle::new()
            .width(40.0)
            .height(line + 16.0)
            .fill(base[8])
            .align_child(Center, Center)
            .child(ui::text("\u{f011}", MENU_TEXT, MENU_FONT).color(base[0]));

        let prompt = Rectangle::new()
            .width(Parent)
            .height(line + 16.0)
            .fill(base[0x0A])
            .padding(8.0)
            .align_child(Start, Center)
            .child(ui::text(&picker.prompt, MENU_TEXT, MENU_FONT).color(base[0]).elide());

        return Rectangle::new()
            .width(width)
            .height(line + 16.0)
            .child(Row::new(vec![Box::new(glyph), Box::new(prompt)]).gap(8.0));
    }

    let prompt = ui::text(&picker.prompt, MENU_TEXT, MENU_FONT).color(base[5]);

    let entry = TextInput::new(INPUT)
        .size(MENU_TEXT)
        .color(base[5])
        .placeholder("Search...")
        .focused()
        .on_change(typed)
        .on_submit(submitted);

    // config.rasi's inputbar: prompt and entry over a dashed bottom border
    Rectangle::new()
        .width(width)
        .height(line + 11.0)
        .child(Column::new(vec![
            Box::new(
                Rectangle::new()
                    .width(width)
                    .height(line + 10.0)
                    .padding(5.0)
                    .child(Row::new(vec![Box::new(prompt), Box::new(entry)]).gap(10.0).align(Center)),
            ),
            Box::new(Rectangle::new().width(width).height(1.0).fill(base[0x0A])),
        ]))
}

#[allow(clippy::too_many_arguments)]
fn list_row(entry: &Entry, font: &str, position: usize, selected: bool, width: f32, height: f32, padding: f32, base: &[Color; 16]) -> Rectangle {
    let (fill, color) = if selected {
        (base[0x0A], base[0])
    } else {
        (Color::TRANSPARENT, base[5])
    };

    // tabs from cliphist would draw as boxes
    let text = entry.text.replace('\t', "  ");

    // a menu's own font only sets the first word, the emoji, the rest stays readable
    let mut parts: Vec<Box<dyn Widget>> = match text.split_once(' ') {
        Some((first, rest)) if !font.is_empty() => vec![
            Box::new(ui::text(first, MENU_TEXT, font).color(color)),
            Box::new(ui::text(rest, MENU_TEXT, MENU_FONT).color(color)),
        ],
        _ => vec![Box::new(ui::text(text, MENU_TEXT, MENU_FONT).color(color))],
    };

    // drun-display-format: "{name} [({generic})]", smaller and lighter
    if !entry.detail.is_empty() {
        parts.push(Box::new(
            ui::text(format!("({})", entry.detail), MENU_TEXT - 3.0, MENU_FONT)
                .color(color)
                .weight(Weight::from(300)),
        ));
    }

    Rectangle::new()
        .width(width)
        .height(height)
        .fill(fill)
        .padding(Padding {
            left: padding,
            right: padding,
            ..Padding::default()
        })
        .align_child(Start, Center)
        .clip()
        .cursor(Pointer)
        .on_click(move |_| picked(position))
        .child(Row::new(parts).gap(8.0).align(Center))
}

fn grid_cell(entry: &Entry, position: usize, selected: bool, width: f32, height: f32, base: &[Color; 16]) -> Rectangle {
    let (fill, color) = if selected {
        (base[0x0A], base[0])
    } else {
        (Color::TRANSPARENT, base[5])
    };

    let image_size = width - 10.0;

    let image = Rectangle::new().width(image_size).height(image_size);

    let image = match &entry.icon {
        Some(path) => image.fill(Image::cover(path).thumbnail(256, 256)),
        None => image.fill(base[1]),
    };

    Rectangle::new()
        .width(width)
        .height(height)
        .fill(fill)
        .padding(5.0)
        .cursor(Pointer)
        .on_click(move |_| picked(position))
        .child(
            Column::new(vec![
                Box::new(image),
                Box::new(ui::text(&entry.text, MENU_TEXT - 3.0, MENU_FONT).color(color).elide()),
            ])
            .gap(4.0)
            .align(Align::Center),
        )
}

// a program from a .desktop file, as rofi's drun mode reads them
#[derive(Clone)]
pub struct App {
    id: String,
    name: String,
    generic: String,
    exec: String,
    terminal: bool,
    directory: String,
    search: String,
}

#[derive(Default)]
pub struct Desktop {
    apps: Vec<App>,
}

impl Service for Desktop {
    fn new() -> Self {
        Self::default()
    }

    // programs installed while the shell runs show up within half a minute
    fn interval() -> Duration {
        Duration::from_secs(30)
    }

    fn listen() {
        loop {
            {
                let apps = scan();
                Self::write().apps = apps;
            }

            std::thread::sleep(Self::interval());
        }
    }
}

fn scan() -> Vec<App> {
    let desktops: Vec<String> = std::env::var("XDG_CURRENT_DESKTOP")
        .unwrap_or_default()
        .split(':')
        .map(str::to_lowercase)
        .collect();

    let mut seen = HashSet::new();
    let mut apps = Vec::new();

    for dir in data_dirs() {
        let root = dir.join("applications");
        let mut files = Vec::new();
        collect(&root, &mut files, 0);

        for file in files {
            let Ok(relative) = file.strip_prefix(&root) else {
                continue;
            };

            // the desktop file id: the path below applications/ with / as -
            let id = relative.to_string_lossy().replace('/', "-");

            if !seen.insert(id.clone()) {
                continue;
            }

            if let Some(app) = parse_desktop(&id, &fs::read_to_string(&file).unwrap_or_default(), &desktops) {
                apps.push(app);
            }
        }
    }

    apps
}

fn collect(dir: &Path, files: &mut Vec<PathBuf>, depth: u32) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };

    for entry in entries.flatten() {
        let path = entry.path();

        if path.is_dir() && depth < 4 {
            collect(&path, files, depth + 1);
        } else if path.extension().is_some_and(|extension| extension == "desktop") {
            files.push(path);
        }
    }
}

fn parse_desktop(id: &str, contents: &str, desktops: &[String]) -> Option<App> {
    let mut fields = HashMap::new();
    let mut in_entry = false;

    for line in contents.lines() {
        let line = line.trim();

        if line.starts_with('[') {
            in_entry = line == "[Desktop Entry]";
            continue;
        }

        // localized keys like Name[de] are left out
        if let Some((key, value)) = line.split_once('=')
            && in_entry
            && !key.contains('[')
        {
            fields.entry(key.trim()).or_insert_with(|| value.trim().to_string());
        }
    }

    let field = |key: &str| fields.get(key).cloned().unwrap_or_default();
    let listed = |key: &str| -> Vec<String> {
        field(key)
            .split(';')
            .filter(|item| !item.is_empty())
            .map(str::to_lowercase)
            .collect()
    };

    if field("Type") != "Application"
        || field("NoDisplay") == "true"
        || field("Hidden") == "true"
        || field("Exec").is_empty()
    {
        return None;
    }

    let only = listed("OnlyShowIn");
    let not = listed("NotShowIn");

    if (!only.is_empty() && !only.iter().any(|desktop| desktops.contains(desktop)))
        || not.iter().any(|desktop| desktops.contains(desktop))
    {
        return None;
    }

    let name = field("Name");
    let generic = field("GenericName");

    // drun-match-fields: name, generic, exec, categories, keywords
    let search = [name.clone(), generic.clone(), field("Exec"), field("Categories"), field("Keywords")]
        .join(" ")
        .to_lowercase();

    Some(App {
        id: id.to_string(),
        name,
        generic,
        exec: strip_field_codes(&field("Exec")),
        terminal: field("Terminal") == "true",
        directory: field("Path"),
        search,
    })
}

// %f, %U and friends are for files and urls, which a launcher never passes
fn strip_field_codes(exec: &str) -> String {
    let mut command = String::new();
    let mut letters = exec.chars();

    while let Some(letter) = letters.next() {
        if letter != '%' {
            command.push(letter);
            continue;
        }

        if let Some('%') = letters.next() {
            command.push('%');
        }
    }

    command.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn history_path() -> PathBuf {
    std::env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home().join(".cache"))
        .join("amane-shell/drun-history")
}

fn history() -> HashMap<String, u32> {
    fs::read_to_string(history_path())
        .unwrap_or_default()
        .lines()
        .filter_map(|line| {
            let (count, id) = line.split_once('\t')?;
            Some((id.to_string(), count.parse().ok()?))
        })
        .collect()
}

fn launch_app(id: &str) {
    let Some(app) = Desktop::read().apps.iter().find(|app| app.id == id).cloned() else {
        return;
    };

    let mut counts = history();
    *counts.entry(app.id.clone()).or_insert(0) += 1;

    let path = history_path();
    if let Some(parent) = path.parent() {
        let _ = fs::create_dir_all(parent);
    }

    let lines: String = counts.iter().map(|(id, count)| format!("{count}\t{id}\n")).collect();
    let _ = fs::write(&path, lines);

    // rofi runs terminal programs in the terminal, sway's is foot
    let mut command = if app.terminal {
        format!("foot -e {}", app.exec)
    } else {
        app.exec.clone()
    };

    if !app.directory.is_empty() {
        command = format!("cd {} && {command}", ui::quote(&app.directory));
    }

    ui::run(&command);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strips_field_codes() {
        assert_eq!(strip_field_codes("firefox %u"), "firefox");
        assert_eq!(strip_field_codes("app --name %c 100%%"), "app --name 100%");
    }

    #[test]
    fn parses_desktop_files() {
        let file = "[Desktop Entry]\nType=Application\nName=Btop\nName[de]=X\nGenericName=Monitor\nExec=btop %f\nTerminal=true\nKeywords=cpu;\n[Desktop Action new]\nExec=other\n";
        let app = parse_desktop("btop.desktop", file, &[String::from("sway")]).expect("parsed");

        assert_eq!(app.name, "Btop");
        assert_eq!(app.exec, "btop");
        assert!(app.terminal);
        assert!(app.search.contains("cpu"));

        let hidden = "[Desktop Entry]\nType=Application\nName=A\nExec=a\nOnlyShowIn=GNOME;\n";
        assert!(parse_desktop("a.desktop", hidden, &[String::from("sway")]).is_none());
    }

    #[test]
    fn parses_rofi_rows() {
        let entry = parse_row("a.png\0icon\x1f/w/a.png");
        assert_eq!(entry.text, "a.png");
        assert_eq!(entry.icon, Some(PathBuf::from("/w/a.png")));
    }

    #[test]
    fn keeps_selection_on_the_page() {
        let mut picker = Picker {
            entries: vec![Entry::default(); 30],
            ..Picker::default()
        };
        picker.filter();
        picker.select(20);
        assert_eq!(picker.offset, 9);
        picker.step(-20);
        assert_eq!((picker.selected, picker.offset), (0, 0));
        picker.step(-1);
        assert_eq!(picker.selected, 29);
    }
}

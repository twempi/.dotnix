use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use amane::Service;

use crate::theme::{config_home, home};

// icon name to file, built once in the background because walking the themes takes seconds
pub struct Icons {
    index: HashMap<String, (u32, PathBuf)>,
}

impl Service for Icons {
    fn new() -> Self {
        Self {
            index: HashMap::new(),
        }
    }

    // amane keeps the built index after listen returns
    fn listen() {
        let index = build();

        Self::write().index = index;
    }
}

impl Icons {
    // a tray item or notification gives a theme icon name, a path, or a file:// link
    pub fn find(&self, name: &str) -> Option<PathBuf> {
        let name = name.strip_prefix("file://").unwrap_or(name);

        if name.is_empty() {
            return None;
        }

        if name.starts_with('/') {
            return Path::new(name).is_file().then(|| PathBuf::from(name));
        }

        self.index.get(name).map(|(_, path)| path.clone())
    }
}

// a tray item's own IconThemePath; walked off the drawing thread, it can be slow
pub fn find_in(dir: &str, name: &str) -> Option<PathBuf> {
    if dir.is_empty() || name.is_empty() {
        return None;
    }

    let mut found = HashMap::new();
    walk(Path::new(dir), 0, 0, &mut found);

    found.remove(name).map(|(_, path)| path)
}

// XDG_DATA_DIRS, plus the NixOS profiles in case the service started without it
pub fn data_dirs() -> Vec<PathBuf> {
    let data_home = env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home().join(".local/share"));

    let user = env::var("USER").unwrap_or_default();

    let mut dirs = vec![data_home];

    dirs.extend(env::split_paths(&env::var_os("XDG_DATA_DIRS").unwrap_or_default()));

    dirs.extend([
        home().join(".nix-profile/share"),
        home().join(".local/state/nix/profile/share"),
        PathBuf::from(format!("/etc/profiles/per-user/{user}/share")),
        PathBuf::from("/run/current-system/sw/share"),
        PathBuf::from("/usr/share"),
    ]);

    let mut unique = Vec::new();

    for dir in dirs {
        if !dir.as_os_str().is_empty() && !unique.contains(&dir) {
            unique.push(dir);
        }
    }

    unique
}

fn gtk_theme() -> String {
    let settings = fs::read_to_string(config_home().join("gtk-3.0/settings.ini")).unwrap_or_default();

    settings
        .lines()
        .find_map(|line| line.strip_prefix("gtk-icon-theme-name="))
        .unwrap_or("hicolor")
        .trim()
        .to_string()
}

// the user's theme, the themes it inherits from, then hicolor
fn theme_order(roots: &[PathBuf]) -> Vec<String> {
    let mut order = vec![gtk_theme()];
    let mut at = 0;

    while at < order.len() && order.len() < 8 {
        for root in roots {
            let index = fs::read_to_string(root.join(&order[at]).join("index.theme")).unwrap_or_default();

            if let Some(inherits) = index.lines().find_map(|line| line.strip_prefix("Inherits=")) {
                for parent in inherits.split(',').map(str::trim) {
                    if !parent.is_empty() && !order.iter().any(|theme| theme == parent) {
                        order.push(parent.to_string());
                    }
                }

                break;
            }
        }

        at += 1;
    }

    if !order.iter().any(|theme| theme == "hicolor") {
        order.push(String::from("hicolor"));
    }

    order
}

fn build() -> HashMap<String, (u32, PathBuf)> {
    let data = data_dirs();

    let mut roots = vec![home().join(".icons")];
    roots.extend(data.iter().map(|dir| dir.join("icons")));

    let order = theme_order(&roots);
    let mut index = HashMap::new();

    for root in &roots {
        let Ok(themes) = fs::read_dir(root) else {
            continue;
        };

        for theme in themes.flatten() {
            let name = theme.file_name().to_string_lossy().to_string();

            // themes the user didn't pick are only a last resort
            let rank = order.iter().position(|wanted| *wanted == name).unwrap_or(order.len());

            walk(&theme.path(), rank as u32 * 10_000, 0, &mut index);
        }
    }

    for dir in &data {
        walk(&dir.join("pixmaps"), 1_000_000, 5, &mut index);
    }

    index
}

/*
 * keeps the best file per name: the earliest theme, then scalable,
 * then the biggest size; symbolic icons only when nothing else exists
 */
fn walk(dir: &Path, base: u32, depth: u32, index: &mut HashMap<String, (u32, PathBuf)>) {
    if depth > 6 {
        return;
    }

    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };

    for entry in entries.flatten() {
        let path = entry.path();

        if path.is_dir() {
            walk(&path, base, depth + 1, index);
            continue;
        }

        let (Some(stem), Some(extension)) = (path.file_stem(), path.extension()) else {
            continue;
        };

        if !matches!(extension.to_str(), Some("png" | "svg")) {
            continue;
        }

        let rank = base + size_rank(&path);
        let stem = stem.to_string_lossy().to_string();

        if index.get(&stem).is_none_or(|(best, _)| rank < *best) {
            index.insert(stem, (rank, path));
        }
    }
}

fn size_rank(path: &Path) -> u32 {
    let text = path.to_string_lossy();

    if text.contains("symbolic") {
        return 5_000;
    }

    if text.contains("scalable") || text.ends_with(".svg") {
        return 0;
    }

    // "48x48", "48x48@2x" or Papirus' "48"
    let size = path
        .components()
        .filter_map(|part| {
            let part = part.as_os_str().to_string_lossy();
            part.split(['x', '@']).next()?.parse::<u32>().ok()
        })
        .max()
        .unwrap_or(0);

    1_000u32.saturating_sub(size)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn prefers_scalable_then_bigger() {
        let svg = size_rank(Path::new("/i/hicolor/scalable/apps/a.svg"));
        let big = size_rank(Path::new("/i/hicolor/256x256/apps/a.png"));
        let small = size_rank(Path::new("/i/Papirus/16x16/apps/a.png"));
        let symbolic = size_rank(Path::new("/i/hicolor/symbolic/apps/a-symbolic.svg"));

        assert!(svg < big && big < small && small < symbolic);
    }
}

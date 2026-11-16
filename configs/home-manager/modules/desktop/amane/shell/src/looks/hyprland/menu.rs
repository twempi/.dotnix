use amane::{
    Align, Center, Color, Column, Image, LayerWindow, Monitor, Padding, Parent, Pointer, Rectangle,
    Row, Service, SpaceBetween, Start, TextInput, Weight, Widget,
};

use crate::logic::compositor;
use crate::logic::menu::{
    Desktop, Entry, INPUT, Picker, Style, dismiss, key, picked, scrolled, submitted, typed,
};
use crate::logic::theme::Theme;
use crate::looks::hyprland::ui::{self, BORDER, MENU_FONT, Placement, TEXT, appear, frame, settle};
use crate::looks::tabs::controls::glyph;

// 16:9 like the monitors, so a wallpaper's preview shows the crop it gets on screen
const PREVIEW_ASPECT: f32 = 16.0 / 9.0;

const PAD: f32 = 8.0;

const GAP: f32 = 6.0;

// the selected row's accent edge
const STRIPE: f32 = 3.0;

const GLYPH_POWER: &str = "\u{EB0D}";

pub fn view(monitor: &Monitor) -> LayerWindow {
    let picker = Picker::read();
    let base = Theme::read().base;

    // read here so the .desktop scan starts with the shell, not on the first launch
    let _desktop = Desktop::read();

    let visible = picker.open() && compositor::shown_on(&picker.monitor, monitor);
    let settled = appear(&format!("menu:{}", monitor.name), visible);

    let width: f32 = match picker.style {
        Style::List | Style::Themes => 560.0,
        Style::Power => 320.0,
        Style::Grid => 980.0,
    };

    let inner = width - (PAD + BORDER) * 2.0;
    let row_height = ui::height_of(&ui::text("A", TEXT, MENU_FONT)) + 14.0;

    let mut sections: Vec<Box<dyn Widget>> = vec![Box::new(input_bar(&picker, inner, row_height, &base))];
    let mut height = row_height + 1.0;

    if !picker.message.is_empty() {
        sections.push(Box::new(
            Rectangle::new()
                .width(inner)
                .height(row_height)
                .fill(base[1])
                .padding(Padding {
                    left: PAD,
                    right: PAD,
                    ..Padding::default()
                })
                .align_child(Start, Center)
                .child(ui::text(&picker.message, TEXT, MENU_FONT).color(base[5]).elide()),
        ));
        height += row_height + GAP;
    }

    let visible_entries: Vec<usize> = picker
        .shown
        .iter()
        .skip(picker.offset)
        .take(picker.page())
        .copied()
        .collect();

    let list: Box<dyn Widget> = if picker.style == Style::Grid {
        let columns = picker.columns();
        let cell = (inner - (columns - 1) as f32 * GAP) / columns as f32;
        let cell_height = (cell - 10.0) / PREVIEW_ASPECT + 10.0 + row_height - 8.0;

        let rows: Vec<Box<dyn Widget>> = visible_entries
            .chunks(columns)
            .enumerate()
            .map(|(row, chunk)| {
                let cells: Vec<Box<dyn Widget>> = chunk
                    .iter()
                    .enumerate()
                    .map(|(column, &index)| {
                        let position = picker.offset + row * columns + column;
                        Box::new(grid_cell(&picker.entries[index], position, position == picker.selected, cell, cell_height, &base))
                            as Box<dyn Widget>
                    })
                    .collect();
                Box::new(Row::new(cells).gap(GAP)) as Box<dyn Widget>
            })
            .collect();

        height += GAP + 3.0 * cell_height + 2.0 * GAP;

        Box::new(Column::new(rows).gap(GAP).height(3.0 * cell_height + 2.0 * GAP))
    } else {
        let mut rows: Vec<Box<dyn Widget>> = Vec::new();

        for (row, &index) in visible_entries.iter().enumerate() {
            // theme rows carry swatches, a hairline keeps them apart
            if picker.style == Style::Themes && row > 0 {
                rows.push(Box::new(Rectangle::new().width(inner).height(1.0).fill(base[1])));
            }

            let position = picker.offset + row;

            rows.push(Box::new(list_row(&picker.entries[index], &picker.font, position, position == picker.selected, inner, row_height, &base)));
        }

        // rofi's dynamic: true, the list shrinks to fit few entries
        let count = visible_entries.len().max(1) as f32;
        let dividers = rows.len().saturating_sub(visible_entries.len()) as f32;
        height += GAP + count * row_height + dividers;

        Box::new(Column::new(rows))
    };

    sections.push(list);

    let panel = settle(
        ui::swallow_clicks(
            frame(Rectangle::new().width(width).height(height + (PAD + BORDER) * 2.0), &base)
                .padding(PAD + BORDER)
                .on_scroll(scrolled)
                .child(Column::new(sections).gap(GAP)),
        ),
        settled,
    );

    ui::overlay("amane-menu", visible, Placement::center(), dismiss, key, panel)
}

// the prompt as a solid tag, then the search, over a hairline
fn input_bar(picker: &Picker, width: f32, height: f32, base: &[Color; 16]) -> Column {
    let tag = if picker.style == Style::Power {
        tag(base[8], height, glyph(GLYPH_POWER, TEXT + 2.0, base[0]))
    } else {
        tag(base[0x0E], height, ui::text(&picker.prompt, TEXT, MENU_FONT).color(base[0]).weight(Weight::Bold))
    };

    let mut parts: Vec<Box<dyn Widget>> = vec![Box::new(tag)];

    if picker.style == Style::Power {
        // the power menu's prompt is the hostname, beside its glyph
        parts.push(Box::new(ui::text(&picker.prompt, TEXT, MENU_FONT).color(base[5]).elide()));
    } else if picker.style != Style::Grid {
        // the wallpaper grid has no search, its letters move the selection (see key)
        parts.push(Box::new(
            TextInput::new(INPUT)
                .size(TEXT)
                .color(base[5])
                .placeholder("Search...")
                .focused()
                .on_change(typed)
                .on_submit(submitted),
        ));
    }

    Column::new(vec![
        Box::new(
            Rectangle::new()
                .width(width)
                .height(height)
                .child(Row::new(parts).height(height).gap(10.0).align(Center)),
        ),
        Box::new(Rectangle::new().width(width).height(1.0).fill(base[2])),
    ])
}

fn tag(fill: Color, height: f32, content: impl Widget + 'static) -> Rectangle {
    Rectangle::new()
        .width((ui::width_of(&content) + 20.0).ceil())
        .height(height)
        .fill(fill)
        .align_child(Center, Center)
        .child(content)
}

fn list_row(entry: &Entry, font: &str, position: usize, selected: bool, width: f32, height: f32, base: &[Color; 16]) -> Rectangle {
    let (fill, color, edge) = if selected {
        (base[2], base[0x0E], base[0x0E])
    } else {
        (Color::TRANSPARENT, base[5], Color::TRANSPARENT)
    };

    // tabs from cliphist would draw as boxes
    let text = entry.text.replace('\t', "  ");

    // a menu's own font only sets the first word, the emoji, the rest stays readable
    let mut parts: Vec<Box<dyn Widget>> = match text.split_once(' ') {
        Some((first, rest)) if !font.is_empty() => vec![
            Box::new(ui::text(first, TEXT, font).color(color)),
            Box::new(ui::text(rest, TEXT, MENU_FONT).color(color)),
        ],
        _ => vec![Box::new(ui::text(text, TEXT, MENU_FONT).color(color))],
    };

    // drun-display-format: "{name} [({generic})]", smaller and lighter
    if !entry.detail.is_empty() {
        parts.push(Box::new(
            ui::text(&entry.detail, TEXT - 2.0, MENU_FONT)
                .color(base[4])
                .weight(Weight::from(300)),
        ));
    }

    let mut content = Row::new(parts).gap(10.0).align(Center);

    if !entry.swatches.is_empty() {
        let swatches: Vec<Box<dyn Widget>> = entry
            .swatches
            .iter()
            // the outline keeps a swatch visible on a background of its own color
            .map(|&swatch| Box::new(Rectangle::new().width(14.0).height(14.0).fill(swatch).border(1.0, base[3])) as Box<dyn Widget>)
            .collect();

        content = Row::new(vec![Box::new(content), Box::new(Row::new(swatches).gap(3.0).align(Center))])
            .width(Parent)
            .justify(SpaceBetween)
            .align(Center);
    }

    Rectangle::new()
        .width(width)
        .height(height)
        .fill(fill)
        .clip()
        .cursor(Pointer)
        .on_click(move |_| picked(position))
        .child(Row::new(vec![
            Box::new(Rectangle::new().width(STRIPE).height(Parent).fill(edge)),
            Box::new(
                Rectangle::new()
                    .width(Parent)
                    .height(Parent)
                    .padding(Padding {
                        left: PAD + 2.0,
                        right: PAD,
                        ..Padding::default()
                    })
                    .align_child(Start, Center)
                    .child(content),
            ),
        ]))
}

fn grid_cell(entry: &Entry, position: usize, selected: bool, width: f32, height: f32, base: &[Color; 16]) -> Rectangle {
    let (fill, border, color) = if selected {
        (base[1], base[0x0E], base[0x0E])
    } else {
        (Color::TRANSPARENT, Color::TRANSPARENT, base[5])
    };

    let image_width = width - 10.0;

    let image = Rectangle::new().width(image_width).height(image_width / PREVIEW_ASPECT);

    let image = match &entry.icon {
        Some(path) => image.fill(Image::cover(path).thumbnail(256, 256)),
        None => image.fill(base[1]),
    };

    Rectangle::new()
        .width(width)
        .height(height)
        .fill(fill)
        .border(2.0, border)
        .padding(5.0)
        .cursor(Pointer)
        .on_click(move |_| picked(position))
        .child(
            Column::new(vec![
                Box::new(image),
                Box::new(ui::text(&entry.text, TEXT - 3.0, MENU_FONT).color(color).elide()),
            ])
            .gap(4.0)
            .align(Align::Center),
        )
}

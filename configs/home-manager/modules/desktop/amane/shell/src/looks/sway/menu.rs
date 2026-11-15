use amane::{
    Align, Center, Color, Column, Image, LayerWindow, Monitor, Padding, Parent,
    Pointer, Rectangle, Row, Service, SpaceBetween, Start, TextInput, Weight, Widget,
};

use crate::logic::compositor;
use crate::logic::menu::{
    Desktop, Entry, INPUT, Picker, Style, dismiss, key, picked, scrolled, submitted, typed,
};
use crate::logic::theme::Theme;
use crate::looks::sway::ui::{self, MENU_FONT, MENU_TEXT, Placement};

// 16:9 like the monitors, so a wallpaper's preview shows the crop it gets on screen
const PREVIEW_ASPECT: f32 = 16.0 / 9.0;

pub fn view(monitor: &Monitor) -> LayerWindow {
    let picker = Picker::read();
    let theme = Theme::read();
    let base = theme.base;

    // read here so the .desktop scan starts with the shell, not on the first launch
    let _desktop = Desktop::read();

    let visible = picker.open() && compositor::shown_on(&picker.monitor, monitor);

    let (width, gap, padding, element_padding): (f32, f32, f32, f32) = match picker.style {
        Style::List | Style::Themes => (600.0, 0.0, 5.0, 5.0),
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
        let columns = picker.columns();
        let cell = (inner - (columns - 1) as f32 * gap) / columns as f32;
        let cell_height = (cell - 10.0) / PREVIEW_ASPECT + 10.0 + row_height;

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
                Box::new(Row::new(cells).gap(gap)) as Box<dyn Widget>
            })
            .collect();

        height += 3.0 * cell_height + 2.0 * gap + gap;

        Box::new(Column::new(rows).gap(gap).height(3.0 * cell_height + 2.0 * gap))
    } else {
        let mut rows: Vec<Box<dyn Widget>> = Vec::new();

        for (row, &index) in visible_entries.iter().enumerate() {
            if picker.style == Style::Themes && row > 0 {
                rows.push(divider(inner, &base));
            }

            let position = picker.offset + row;

            rows.push(Box::new(list_row(&picker.entries[index], &picker.font, position, position == picker.selected, inner, row_height, element_padding, &base)));
        }

        // rofi's dynamic: true, the list shrinks to fit few entries
        let count = visible_entries.len().max(1) as f32;
        let dividers = rows.len().saturating_sub(visible_entries.len()) as f32;
        height += count * row_height + (count - 1.0) * gap + dividers + gap.max(5.0);

        Box::new(Column::new(rows).gap(gap))
    };

    sections.push(list);

    let panel = ui::swallow_clicks(
        Rectangle::new()
            .width(width)
            .height(height + padding * 2.0 + 2.0)
            .fill(base[0])
            .border(1.0, base[0x0E])
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
            .fill(base[0x0E])
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

    let mut parts: Vec<Box<dyn Widget>> = vec![Box::new(prompt)];

    // the wallpaper grid has no search, its letters move the selection (see key)
    if picker.style != Style::Grid {
        parts.push(Box::new(entry));
    }

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
                    .child(Row::new(parts).gap(10.0).align(Center)),
            ),
            Box::new(Rectangle::new().width(width).height(1.0).fill(base[0x0E])),
        ]))
}

#[allow(clippy::too_many_arguments)]
fn list_row(entry: &Entry, font: &str, position: usize, selected: bool, width: f32, height: f32, padding: f32, base: &[Color; 16]) -> Rectangle {
    let (fill, color) = if selected {
        (base[0x0E], base[0])
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

    let mut content = Row::new(parts).gap(8.0).align(Center);

    if !entry.swatches.is_empty() {
        let swatches: Vec<Box<dyn Widget>> = entry
            .swatches
            .iter()
            // the outline keeps a swatch visible on the accent fill of its own color
            .map(|&swatch| Box::new(Rectangle::new().width(14.0).height(14.0).fill(swatch).border(1.0, base[0])) as Box<dyn Widget>)
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
        .padding(Padding {
            left: padding,
            right: padding,
            ..Padding::default()
        })
        .align_child(Start, Center)
        .clip()
        .cursor(Pointer)
        .on_click(move |_| picked(position))
        .child(content)
}

fn grid_cell(entry: &Entry, position: usize, selected: bool, width: f32, height: f32, base: &[Color; 16]) -> Rectangle {
    let (fill, color) = if selected {
        (base[0x0E], base[0])
    } else {
        (Color::TRANSPARENT, base[5])
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

// the dashes NvChad's theme picker puts between its rows
fn divider(width: f32, base: &[Color; 16]) -> Box<dyn Widget> {
    const DASH: f32 = 3.0;

    let dashes = ((width + DASH) / (DASH * 2.0)) as usize;

    Box::new(
        Row::new(
            (0..dashes)
                .map(|_| Box::new(Rectangle::new().width(DASH).height(1.0).fill(base[2])) as Box<dyn Widget>)
                .collect(),
        )
        .gap(DASH),
    )
}

use std::sync::atomic::Ordering;

use amane::{
    Center, Column, End, Image, Padding, Parent, Pointer, Rectangle, Row, Service, Weight, Widget,
    children,
};

use crate::logic::panel::audio::{
    AudioData, AudioTab, DIRTY, Menu, MenuAction, MenuItem, Stream, Target, close_menu,
    run_menu_action, set_volume, toggle_menu, toggle_mute,
};
use crate::looks::sway::ui::{height_of, width_of};
use super::controls::{
    CONTROL, CONTROL_SM, FONT_BODY, FONT_CAPTION, FONT_TITLE, RADIUS_LG, RADIUS_MD, SPACE_MD, SPACE_SM,
    SPACE_XS, Ui, Variant, elide_middle, glyph, hoverable, icon_button, label, scroll_view, sized_card,
    slider,
};

const GLYPH_VOLUME: &str = "\u{EB51}";

const GLYPH_VOLUME_MUTE: &str = "\u{F1C3}";

const GLYPH_MIC: &str = "\u{EAF0}";

const GLYPH_MIC_MUTE: &str = "\u{ED16}";

const GLYPH_MORE: &str = "\u{EA94}";

const GLYPH_HEADPHONES: &str = "\u{EABD}";

const GLYPH_CHECK: &str = "\u{EA5E}";

const DEVICE_CARD: f32 = 104.0;

const ROW: f32 = 54.0;

const ICON: f32 = 28.0;

const SLIDER_COMPACT: f32 = 20.0;

const VALUE_WIDTH: f32 = 60.0;

const MENU_PADDING: f32 = 6.0;

const MENU_ITEM: f32 = 32.0;

const MENU_SEPARATOR: f32 = 10.0;

const MENU_SLOT: f32 = 16.0;

const MENU_SIDES: f32 = 16.0;

const MENU_OVERHANG: f32 = 8.0;

const DEFAULT_DEVICE: &str = "Default device";

fn device_card(ui: &Ui, data: &AudioData, input: bool, width: f32, center_x: f32) -> Rectangle {
    let c = &ui.c;
    let inner = width - SPACE_MD * 2.0;
    let (title, device) = if input {
        ("Input", data.default_source_device())
    } else {
        ("Output", data.default_sink_device())
    };

    let name = device.map(|device| device.name.clone()).unwrap_or_default();
    let description = device.map_or("No device", |device| device.description.as_str());
    let volume = device.map_or(0.0, |device| device.volume);
    let muted = device.is_some_and(|device| device.muted);
    let target = if input { Target::Source(name.clone()) } else { Target::Sink(name.clone()) };

    let value_width = width_of(&label("888%", FONT_BODY, c.on_surface).weight(Weight::Bold));
    let slider_width = inner - SPACE_SM - value_width - SPACE_SM - CONTROL_SM;

    let items: Vec<MenuItem> = if input {
        data.sources
            .iter()
            .map(|device| MenuItem {
                text: device.description.clone(),
                selected: device.name == data.default_source,
                action: Some(MenuAction::DefaultSource(device.name.clone())),
            })
            .collect()
    } else {
        data.sinks
            .iter()
            .map(|(device, _)| MenuItem {
                text: device.description.clone(),
                selected: device.name == data.default_sink,
                action: Some(MenuAction::DefaultSink(device.name.clone())),
            })
            .collect()
    };

    let min_width = 280.0f32.min(width);
    let menu = Menu {
        id: title.to_string(),
        items,
        center_x,
        y: SPACE_MD + 1.0 + CONTROL + SPACE_XS,
        min_width,
        max_width: 420.0,
    };

    let (muted_glyph, normal_glyph) = if input {
        (GLYPH_MIC_MUTE, GLYPH_MIC)
    } else {
        (GLYPH_VOLUME_MUTE, GLYPH_VOLUME)
    };

    let mute_target = target.clone();

    let body = Column::new(children![
        Row::new(children![
            Column::new(children![
                label(title, FONT_TITLE, c.on_surface).weight(Weight::Bold),
                label(elide_middle(description, FONT_CAPTION, inner - CONTROL_SM - SPACE_SM), FONT_CAPTION, c.variant),
            ])
            .width(Parent),
            icon_button(ui, format!("audio:menu:{title}"), GLYPH_MORE, (CONTROL_SM, 13.0, RADIUS_MD), Variant::Ghost)
                .on_click(move |_| toggle_menu(menu.clone())),
        ])
        .width(Parent)
        .height(CONTROL)
        .gap(SPACE_SM)
        .align(Center),
        Row::new(children![
            slider(ui, format!("audio:volume:{title}"), (slider_width, CONTROL), volume, move |value| {
                set_volume(target.clone(), value);
            }),
            Rectangle::new().width(value_width).height(CONTROL).align_child(End, Center).child(
                label(format!("{}%", (volume * 100.0).round() as i32), FONT_BODY, c.on_surface).weight(Weight::Bold),
            ),
            icon_button(
                ui,
                format!("audio:mute:{title}"),
                if muted { muted_glyph } else { normal_glyph },
                (CONTROL_SM, FONT_BODY, RADIUS_MD),
                if muted { Variant::Destructive } else { Variant::Default },
            )
            .on_click(move |_| toggle_mute(&mute_target)),
        ])
        .width(Parent)
        .height(CONTROL)
        .gap(SPACE_SM)
        .align(Center),
    ])
    .width(Parent)
    .gap(SPACE_XS);

    sized_card(ui, width, DEVICE_CARD).child(body)
}

fn app_icon(ui: &Ui, stream: &Stream) -> Rectangle {
    let frame = Rectangle::new().width(ICON).height(ICON).radius(RADIUS_MD).clip();

    match &stream.icon {
        Some(path) => frame.fill(Image::contain(path).thumbnail(56, 56)),
        None => frame.fill(ui.c.surface),
    }
}

fn program_row(ui: &Ui, data: &AudioData, stream: &Stream, width: f32, menu_y: f32) -> Rectangle {
    let c = &ui.c;
    let index = stream.index;
    let target = Target::Stream(index);
    let mute_target = target.clone();

    let name = label(stream.name.clone(), FONT_BODY, c.on_surface).weight(Weight::Bold);

    let mut title: Vec<Box<dyn Widget>> = vec![Box::new(name)];

    if !stream.subtitle.is_empty() {
        title.push(Box::new(
            Rectangle::new()
                .width(Parent)
                .height(18.0)
                .align_child(amane::Start, Center)
                .child(label(stream.subtitle.clone(), FONT_CAPTION, c.variant).elide()),
        ));
    }

    let inner = width - SPACE_MD * 2.0 - ICON - SPACE_SM - SPACE_MD - CONTROL_SM * 2.0 - SPACE_XS;

    let pinned = stream.sink != data.default_sink_index();
    let mut items = vec![
        MenuItem {
            text: DEFAULT_DEVICE.to_string(),
            selected: !pinned,
            action: Some(MenuAction::RouteDefault(index)),
        },
        MenuItem {
            text: String::new(),
            selected: false,
            action: None,
        },
    ];

    items.extend(data.sinks.iter().map(|(device, sink)| MenuItem {
        text: device.description.clone(),
        selected: pinned && *sink == stream.sink,
        action: Some(MenuAction::Route(index, device.name.clone())),
    }));

    let menu = Menu {
        id: format!("route:{index}"),
        items,
        center_x: width - CONTROL_SM - SPACE_XS - CONTROL_SM / 2.0 - SPACE_MD + SPACE_MD,
        y: menu_y,
        min_width: 240.0,
        max_width: 420.0,
    };

    let routing = icon_button(
        ui,
        format!("audio:route:{index}"),
        GLYPH_HEADPHONES,
        (CONTROL_SM, FONT_BODY, RADIUS_MD),
        if pinned { Variant::Outline } else { Variant::Ghost },
    )
    .on_click(move |_| toggle_menu(menu.clone()));

    let mute = icon_button(
        ui,
        format!("audio:stream-mute:{index}"),
        if stream.muted { GLYPH_VOLUME_MUTE } else { GLYPH_VOLUME },
        (CONTROL_SM, FONT_BODY, RADIUS_MD),
        if stream.muted { Variant::Destructive } else { Variant::Default },
    )
    .on_click(move |_| toggle_mute(&mute_target));

    let content = Row::new(children![
        Row::new(children![
            app_icon(ui, stream),
            Column::new(children![
                Row::new(children![
                    Row::new(title).width(Parent).height(18.0).gap(SPACE_XS).align(Center),
                    Rectangle::new().width(VALUE_WIDTH).height(18.0).align_child(End, Center).child(
                        label(format!("{}%", (stream.volume * 100.0).round() as i32), FONT_BODY, c.on_surface)
                            .weight(Weight::Bold),
                    ),
                ])
                .width(Parent)
                .height(18.0)
                .gap(SPACE_SM)
                .align(Center),
                slider(ui, format!("audio:stream:{index}"), (inner, SLIDER_COMPACT), stream.volume, move |value| {
                    set_volume(target.clone(), value);
                }),
            ])
            .width(Parent),
        ])
        .width(Parent)
        .height(CONTROL_SM + SPACE_XS + 2.0)
        .gap(SPACE_SM)
        .align(Center),
        Row::new(children![routing, mute]).gap(SPACE_XS).align(Center),
    ])
    .width(Parent)
    .height(CONTROL_SM + SPACE_XS + 2.0)
    .gap(SPACE_MD)
    .align(Center);

    Rectangle::new()
        .width(width)
        .height(ROW)
        .radius(RADIUS_MD)
        .fill(c.surface)
        .padding(Padding {
            left: SPACE_MD,
            right: SPACE_MD,
            top: SPACE_SM,
            bottom: SPACE_SM,
        })
        .child(content)
}

fn empty_card(ui: &Ui, width: f32) -> Rectangle {
    let body = Column::new(children![
        label("No Application Audio", FONT_BODY, ui.c.on_surface).weight(Weight::Bold),
        label("No application playback streams are currently available.", FONT_CAPTION, ui.c.variant),
    ])
    .width(Parent)
    .gap(SPACE_XS);

    Rectangle::new()
        .width(width)
        .height(height_of(&body) + SPACE_MD * 2.0)
        .radius(RADIUS_MD)
        .fill(ui.c.surface)
        .padding(SPACE_MD)
        .child(body)
}

pub fn view(ui: &Ui, width: f32, height: f32) -> Column {
    let tab = AudioTab::read();
    let data = &tab.data;
    let card_width = (width - SPACE_MD) / 2.0;

    let cards = Row::new(children![
        device_card(ui, data, false, card_width, card_width / 2.0),
        device_card(ui, data, true, card_width, card_width + SPACE_MD + card_width / 2.0),
    ])
    .width(width)
    .height(DEVICE_CARD)
    .gap(SPACE_MD);

    let apps_height = height - DEVICE_CARD - SPACE_MD;
    let title = label("Application Volumes", FONT_TITLE, ui.c.on_surface).weight(Weight::Bold);
    let title_height = height_of(&title);
    let list_height = apps_height - SPACE_MD * 2.0 - title_height - SPACE_SM;
    let list_top = DEVICE_CARD + SPACE_MD + SPACE_MD + title_height + SPACE_SM;
    let offset = ui.scroll_offset("audio-programs");

    let list = scroll_view(ui, "audio-programs", (width - SPACE_MD * 2.0, list_height), |list_width| {
        if data.streams.is_empty() {
            return Column::new(children![empty_card(ui, list_width)]).width(list_width);
        }

        let rows: Vec<Box<dyn Widget>> = data
            .streams
            .iter()
            .enumerate()
            .map(|(position, stream)| {
                let menu_y = list_top + position as f32 * (ROW + SPACE_SM) + SPACE_SM + CONTROL_SM + SPACE_XS - offset;

                Box::new(program_row(ui, data, stream, list_width, menu_y)) as Box<dyn Widget>
            })
            .collect();

        Column::new(rows).width(list_width).gap(SPACE_SM)
    });

    let apps = sized_card(ui, width, apps_height).child(
        Column::new(children![title, list]).width(Parent).height(Parent).gap(SPACE_SM),
    );

    Column::new(children![cards, apps]).width(width).height(height).gap(SPACE_MD)
}

fn menu_item(ui: &Ui, item: &MenuItem, index: usize, width: f32) -> Box<dyn Widget> {
    let c = &ui.c;

    let Some(action) = item.action.clone() else {
        return Box::new(
            Rectangle::new().width(Parent).height(MENU_SEPARATOR).align_child(Center, Center).child(
                Rectangle::new().width(Parent).height(1.0).fill(c.outline),
            ),
        );
    };

    let key = format!("menu:{index}");
    let hovered = ui.hovered(&key);
    let color = if hovered { c.on_hover } else { c.on_surface };
    let text_width = width - MENU_SIDES - MENU_SLOT;

    let slot = Rectangle::new().width(MENU_SLOT).height(MENU_ITEM).align_child(amane::Start, Center);
    let slot = if item.selected { slot.child(glyph(GLYPH_CHECK, FONT_CAPTION - 1.0, color)) } else { slot };

    let row = Rectangle::new()
        .width(Parent)
        .height(MENU_ITEM)
        .fill(if hovered { c.hover } else { amane::Color::TRANSPARENT })
        .cursor(Pointer)
        .padding(Padding {
            left: MENU_SIDES / 2.0,
            right: MENU_SIDES / 2.0,
            ..Padding::default()
        })
        .on_click(move |_| {
            run_menu_action(&action);
            close_menu();
            DIRTY.store(true, Ordering::Relaxed);
        })
        .child(
            Row::new(children![
                slot,
                label(elide_middle(&item.text, FONT_CAPTION, text_width), FONT_CAPTION, color),
            ])
            .height(MENU_ITEM)
            .align(Center),
        );

    Box::new(hoverable(row, key))
}

// on top of the panel, free to hang over its edge as Noctalia's popup does
pub fn menu_layer(ui: &Ui, panel_width: f32, panel_height: f32, body_x: f32, body_y: f32) -> Vec<Box<dyn Widget>> {
    let Some(menu) = AudioTab::read().menu.clone() else {
        return Vec::new();
    };

    let text_width = menu
        .items
        .iter()
        .map(|item| width_of(&label(item.text.clone(), FONT_CAPTION, ui.c.on_surface)))
        .fold(0.0, f32::max);

    let width = (text_width + MENU_SLOT + MENU_SIDES + MENU_PADDING * 2.0)
        .clamp(menu.min_width, menu.max_width);

    let height = menu
        .items
        .iter()
        .map(|item| if item.action.is_some() { MENU_ITEM } else { MENU_SEPARATOR })
        .sum::<f32>()
        + MENU_PADDING * 2.0;

    let x = (body_x + menu.center_x - width / 2.0)
        .min(panel_width + MENU_OVERHANG - width)
        .max(-MENU_OVERHANG);
    let y = (body_y + menu.y).min(panel_height + MENU_OVERHANG - height);

    let items: Vec<Box<dyn Widget>> = menu
        .items
        .iter()
        .enumerate()
        .map(|(index, item)| menu_item(ui, item, index, width))
        .collect();

    vec![
        Box::new(Rectangle::new().width(panel_width).height(panel_height).on_click(|_| {
            close_menu();
        })),
        Box::new(
            Rectangle::new()
                .width(width)
                .height(height)
                .radius(RADIUS_LG)
                .fill(ui.c.surface)
                .border(1.0, ui.c.outline)
                .padding(MENU_PADDING)
                .translate(x, y)
                .on_click(|_| {})
                .child(Column::new(items).width(Parent)),
        ),
    ]
}

{
home.file.".config/vesktop/themes/stylix.css".text = ''
/**
 * @name system24 (rosé pine)
 * @description a tui-like discord theme. based on rosé pine theme (https://rosepinetheme.com).
 * @author refact0r
 * @version 2.0.0
 * @invite nz87hXyvcy
 * @website https://github.com/refact0r/system24
 * @source https://github.com/refact0r/system24/blob/master/theme/system24-rose-pine.theme.css
 * @authorId 508863359777505290
 * @authorLink https://www.refact0r.dev
*/

/* import theme modules */
@import url('https://refact0r.github.io/system24/build/system24.css');

body {
    /* font, change to '' for default discord font */
    --font: 'Fira Code'; /* change to '' for default discord font */
    --code-font: 'Fira Code'; /* change to '' for default discord font */
    font-weight: 300; /* text font weight. 300 is light, 400 is normal. DOES NOT AFFECT BOLD TEXT */
    letter-spacing: -0.05ch; /* decreases letter spacing for better readability. recommended on monospace fonts.*/
    word-spacing: -4px; /* WHY IS SPACES SO BIG */

    /* sizes */
    --gap: 12px; /* spacing between panels */
    --divider-thickness: 4px; /* thickness of unread messages divider and highlighted message borders */
    --border-thickness: 2px; /* thickness of borders around main panels. DOES NOT AFFECT OTHER BORDERS */
    --border-hover-transition: 0.2s ease; /* transition for borders when hovered */

    /* animation/transition options */
    --animations: on; /* off: disable animations/transitions, on: enable animations/transitions */
    --list-item-transition: 0.2s ease; /* transition for list items */
    --dms-icon-svg-transition: 0.4s ease; /* transition for the dms icon */

    /* top bar options */
    --top-bar-height: var(--gap); /* height of the top bar (discord default is 36px, old discord style is 24px, var(--gap) recommended if button position is set to titlebar) */
    --top-bar-button-position: titlebar; /* off: default position, hide: hide buttons completely, serverlist: move inbox button to server list, titlebar: move inbox button to channel titlebar (will hide title) */
    --top-bar-title-position: off; /* off: default centered position, hide: hide title completely, left: left align title (like old discord) */
    --subtle-top-bar-title: off; /* off: default, on: hide the icon and use subtle text color (like old discord) */

    /* window controls */
    --custom-window-controls: off; /* off: default window controls, on: custom window controls */
    --window-control-size: 14px; /* size of custom window controls */

    /* dms button options */
    --custom-dms-icon: hide; /* off: use default discord icon, hide: remove icon entirely, custom: use custom icon */
    --dms-icon-svg-url: url('https://upload.wikimedia.org/wikipedia/commons/c/c4/Font_Awesome_5_solid_moon.svg'); /* icon svg url. MUST BE A SVG. */
    --dms-icon-svg-size: 90%; /* size of the svg (css mask-size property) */
    --dms-icon-color-before: var(--icon-secondary); /* normal icon color */
    --dms-icon-color-after: var(--white); /* icon color when button is hovered/selected */
    --custom-dms-background: image; /* off to disable, image to use a background image (must set url variable below), color to use a custom color/gradient */
    --dms-background-image-url: url('https://raw.githubusercontent.com/rose-pine/rose-pine-theme/main/assets/icon.png'); /* url of the background image */
    --dms-background-image-size: cover; /* size of the background image (css background-size property) */
    --dms-background-color: linear-gradient(70deg, var(--blue-2), var(--purple-2), var(--red-2)); /* fixed color/gradient (css background property) */

    /* background image options */
    --background-image: off; /* off: no background image, on: enable background image (must set url variable below) */
    --background-image-url: url(''); /* url of the background image */

    /* transparency/blur options */
    /* NOTE: TO USE TRANSPARENCY/BLUR, YOU MUST HAVE TRANSPARENT BG COLORS. FOR EXAMPLE: --bg-4: hsla(220, 15%, 10%, 0.7); */
    --transparency-tweaks: off; /* off: no changes, on: remove some elements for better transparency */
    --remove-bg-layer: off; /* off: no changes, on: remove the base --bg-3 layer for use with window transparency (WILL OVERRIDE BACKGROUND IMAGE) */
    --panel-blur: off; /* off: no changes, on: blur the background of panels */
    --blur-amount: 12px; /* amount of blur */
    --bg-floating: var(--bg-3); /* set this to a more opaque color if floating panels look too transparent. only applies if panel blur is on  */

    /* other options */
    --small-user-panel: on; /* off: default user panel, on: smaller user panel like in old discord */

    /* unrounding options */
    --unrounding: on; /* off: default, on: remove rounded corners from panels */

    /* styling options */
    --custom-spotify-bar: on; /* off: default, on: custom text-like spotify progress bar */
    --ascii-titles: on; /* off: default, on: use ascii font for titles at the start of a channel */
    --ascii-loader: system24; /* off: default, system24: use system24 ascii loader, cats: use cats loader */

    /* panel labels */
    --panel-labels: on; /* off: default, on: add labels to panels */
    --label-color: var(--text-muted); /* color of labels */
    --label-font-weight: 500; /* font weight of labels */
}

/* color options */
:root {
    --colors: on;

    /* =========================
       TEXT COLORS
       ========================= */

    --text-0: var(--stylix-base00); /* text on colored elements */
    --text-1: var(--stylix-base07); /* brightest text */
    --text-2: var(--stylix-base06); /* headings */
    --text-3: var(--stylix-base05); /* normal text */
    --text-4: var(--stylix-base04); /* secondary text/icons */
    --text-5: var(--stylix-base03); /* muted text */

    /* =========================
       BACKGROUNDS
       ========================= */

    --bg-1: var(--stylix-base02); /* pressed buttons */
    --bg-2: var(--stylix-base01); /* buttons */
    --bg-3: var(--stylix-base01); /* panels / separators */
    --bg-4: var(--stylix-base00); /* main background */

    --hover: color-mix(in srgb, var(--stylix-base05) 10%, transparent);
    --active: color-mix(in srgb, var(--stylix-base05) 20%, transparent);
    --active-2: color-mix(in srgb, var(--stylix-base05) 30%, transparent);
    --message-hover: color-mix(in srgb, var(--stylix-base05) 8%, transparent);

    /* =========================
       ACCENTS
       ========================= */

    --accent-1: var(--stylix-magenta); /* links */
    --accent-2: var(--stylix-cyan);    /* subtle accents */
    --accent-3: var(--stylix-blue);    /* buttons */
    --accent-4: color-mix(in srgb, var(--stylix-blue) 85%, white);
    --accent-5: color-mix(in srgb, var(--stylix-blue) 70%, black);

    --accent-new: var(--stylix-red);

    --mention: linear-gradient(
        to right,
        color-mix(in srgb, var(--stylix-magenta) 20%, transparent) 40%,
        transparent
    );

    --mention-hover: linear-gradient(
        to right,
        color-mix(in srgb, var(--stylix-magenta) 30%, transparent) 40%,
        transparent
    );

    --reply: linear-gradient(
        to right,
        color-mix(in srgb, var(--stylix-base05) 20%, transparent) 40%,
        transparent
    );

    --reply-hover: linear-gradient(
        to right,
        color-mix(in srgb, var(--stylix-base05) 30%, transparent) 40%,
        transparent
    );

    /* =========================
       STATUS COLORS
       ========================= */

    --online: var(--stylix-green);
    --dnd: var(--stylix-red);
    --idle: var(--stylix-yellow);
    --streaming: var(--stylix-magenta);
    --offline: var(--stylix-base04);

    /* =========================
       BORDERS
       ========================= */

    --border-light: var(--hover);
    --border: var(--active);
    --border-hover: var(--accent-2);
    --button-border: color-mix(in srgb, var(--stylix-base07) 10%, transparent);

    /* =========================
       BASE COLOR ALIASES
       (used internally by system24)
       ========================= */

    --red-1: var(--stylix-red);
    --red-2: var(--stylix-red);
    --red-3: var(--stylix-red);
    --red-4: var(--stylix-red);
    --red-5: var(--stylix-red);

    --green-1: var(--stylix-green);
    --green-2: var(--stylix-green);
    --green-3: var(--stylix-green);
    --green-4: var(--stylix-green);
    --green-5: var(--stylix-green);

    --blue-1: var(--stylix-blue);
    --blue-2: var(--stylix-blue);
    --blue-3: var(--stylix-blue);
    --blue-4: var(--stylix-blue);
    --blue-5: var(--stylix-blue);

    --yellow-1: var(--stylix-yellow);
    --yellow-2: var(--stylix-yellow);
    --yellow-3: var(--stylix-yellow);
    --yellow-4: var(--stylix-yellow);
    --yellow-5: var(--stylix-yellow);

    --purple-1: var(--stylix-magenta);
    --purple-2: var(--stylix-magenta);
    --purple-3: var(--stylix-magenta);
    --purple-4: var(--stylix-magenta);
    --purple-5: var(--stylix-magenta);
}
  '';
}



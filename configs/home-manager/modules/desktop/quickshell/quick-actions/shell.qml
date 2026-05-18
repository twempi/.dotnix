import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

ShellRoot {
  id: root

  property string activeOverlay: ""
  property string trackedScreenName: ""

  property string launcherQuery: ""
  property int launcherSelectedIndex: 0
  readonly property var apps: DesktopEntries.applications.values
  readonly property var filteredApps: [...apps].filter(function(app) {
    var text = appSearchText(app);
    return root.launcherQuery.length === 0 || text.indexOf(root.launcherQuery.toLowerCase()) !== -1;
  }).sort(compareApps)

  property int powerSelectedIndex: 0
  property string host: "Power"
  property string uptime: "unknown"
  readonly property var powerActions: [
    {"name": "Lock", "label": "Lock", "icon": Qt.resolvedUrl("icons/lock.svg"), "action": "lock", "shortcut": ""},
    {"name": "Suspend", "label": "Suspend", "icon": Qt.resolvedUrl("icons/suspend.svg"), "action": "suspend", "shortcut": "S"},
    {"name": "Logout", "label": "Logout", "icon": Qt.resolvedUrl("icons/logout.svg"), "action": "logout", "shortcut": "L"},
    {"name": "Reboot", "label": "Reboot", "icon": Qt.resolvedUrl("icons/reboot.svg"), "action": "reboot", "shortcut": "R"},
    {"name": "Shutdown", "label": "Shutdown", "icon": Qt.resolvedUrl("icons/shutdown.svg"), "action": "shutdown", "shortcut": "P"},
  ]

  property var wallpapers: []
  property string wallpaperQuery: ""
  property int wallpaperSelectedIndex: 0
  property string wallpaperStatusText: wallpaperListProcess.running && wallpapers.length === 0 ? "Loading wallpapers" : (wallpapers.length + " wallpapers")
  property string wallpaperErrorText: ""
  property double wallpaperLastLoadMs: 0
  readonly property var filteredWallpapers: wallpapers.filter(function(wallpaper) {
    return root.wallpaperQuery.length === 0 || wallpaper.name.toLowerCase().indexOf(root.wallpaperQuery.toLowerCase()) !== -1;
  })

  property var emojiItems: []
  property string emojiQuery: ""
  property int emojiSelectedIndex: 0
  property string emojiStatusText: emojiListProcess.running && emojiItems.length === 0 ? "Loading emoji" : (emojiItems.length + " emoji")
  property string emojiErrorText: ""
  property double emojiLastLoadMs: 0
  readonly property var filteredEmojiItems: emojiItems.filter(function(item) {
    return root.emojiQuery.length === 0 || root.pickerSearchText(item).indexOf(root.emojiQuery.toLowerCase()) !== -1;
  })

  property var clipboardItems: []
  property string clipboardQuery: ""
  property int clipboardSelectedIndex: 0
  property string clipboardStatusText: clipboardListProcess.running && clipboardItems.length === 0 ? "Loading clipboard" : (clipboardItems.length + " clips")
  property string clipboardErrorText: ""
  property double clipboardLastLoadMs: 0
  readonly property var filteredClipboardItems: clipboardItems.filter(function(item) {
    return root.clipboardQuery.length === 0 || root.pickerSearchText(item).indexOf(root.clipboardQuery.toLowerCase()) !== -1;
  })

  readonly property var genericOverlayKinds: ["monitors", "stewart", "music", "battery", "calendar", "network", "focustime", "volume", "guide"]
  property string genericOverlayTitle: ""
  property string genericOverlaySubtitle: ""
  property string genericOverlayError: ""
  property var genericOverlayRows: []
  property var genericOverlayActions: []
  property int genericSelectedAction: 0
  property string pendingGenericKind: ""
  property int focusSecondsRemaining: 25 * 60
  property bool focusRunning: false

  readonly property string sessionName: (
    (Quickshell.env("XDG_CURRENT_DESKTOP") || "") + " " +
    (Quickshell.env("XDG_SESSION_DESKTOP") || "") + " " +
    (Quickshell.env("DESKTOP_SESSION") || "")
  ).toLowerCase()
  readonly property bool mangoSession: sessionName.indexOf("mango") !== -1
  readonly property bool genericOverlayActive: root.genericOverlayKinds.indexOf(root.activeOverlay) !== -1

  function targetScreen() {
    if (root.trackedScreenName.length > 0) {
      for (var i = 0; i < Quickshell.screens.length; i++) {
        if (Quickshell.screens[i].name === root.trackedScreenName) {
          return Quickshell.screens[i];
        }
      }
    }

    return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
  }

  function activeScreenWidth() {
    var screen = root.targetScreen();
    return screen && screen.width > 0 ? screen.width : 1040;
  }

  function activeScreenHeight() {
    var screen = root.targetScreen();
    return screen && screen.height > 0 ? screen.height : 640;
  }

  function launcherPanelWidth(screenWidth) {
    return screenWidth >= 680 ? Math.min(640, screenWidth - 40) : Math.max(1, screenWidth - 24);
  }

  function launcherPanelHeight(screenHeight) {
    return screenHeight >= 560 ? Math.min(520, screenHeight - 40) : Math.max(1, screenHeight - 24);
  }

  function powerPanelWidth(screenWidth) {
    return screenWidth >= 390 ? 350 : Math.max(1, screenWidth - 24);
  }

  function powerPanelHeight(screenHeight) {
    return screenHeight >= 430 ? 390 : Math.max(1, screenHeight - 24);
  }

  function wallpaperPanelWidth(screenWidth) {
    return screenWidth >= 740 ? Math.min(1000, screenWidth - 40) : Math.max(1, screenWidth - 24);
  }

  function wallpaperPanelHeight(screenHeight) {
    return screenHeight >= 460 ? Math.min(600, screenHeight - 40) : Math.max(1, screenHeight - 24);
  }

  function genericPanelWidth(screenWidth) {
    return screenWidth >= 540 ? 500 : Math.max(1, screenWidth - 24);
  }

  function genericPanelHeight(screenHeight) {
    return screenHeight >= 500 ? Math.min(460, screenHeight - 40) : Math.max(1, screenHeight - 24);
  }

  function centerMarginX(panelWidth) {
    return Math.max(0, Math.round((root.activeScreenWidth() - panelWidth) / 2));
  }

  function centerMarginY(panelHeight) {
    return Math.max(0, Math.round((root.activeScreenHeight() - panelHeight) / 2));
  }

  function updateTrackedScreen(screenName) {
    var name = screenName.trim();
    if (name.length > 0) {
      root.trackedScreenName = name;
    }
  }

  function activateOverlay(kind) {
    if (kind !== "launcher" && kind !== "power" && kind !== "wallpaper" && kind !== "emoji" && kind !== "clipboard" && root.genericOverlayKinds.indexOf(kind) === -1) {
      return "unknown overlay: " + kind;
    }

    if (root.activeOverlay === kind) {
      root.closeActiveOverlay();
      return "ok";
    }

    if (kind === "launcher") {
      root.launcherQuery = "";
      root.launcherSelectedIndex = root.filteredApps.length > 0 ? 0 : -1;
      root.activeOverlay = "launcher";
      Qt.callLater(root.focusLauncher);
    } else if (kind === "power") {
      root.powerSelectedIndex = 0;
      refreshPowerInfo();
      root.activeOverlay = "power";
      Qt.callLater(root.focusPower);
    } else if (kind === "wallpaper") {
      root.wallpaperQuery = "";
      root.wallpaperSelectedIndex = root.filteredWallpapers.length > 0 ? 0 : -1;
      if (wallpaperListStale()) {
        refreshWallpaperList();
      }
      root.activeOverlay = "wallpaper";
      Qt.callLater(root.focusWallpaper);
    } else if (kind === "emoji") {
      root.emojiQuery = "";
      root.emojiSelectedIndex = root.filteredEmojiItems.length > 0 ? 0 : -1;
      if (root.emojiItems.length === 0 && !emojiListProcess.running) {
        refreshEmojiList();
      }
      root.activeOverlay = "emoji";
      Qt.callLater(root.focusEmoji);
    } else if (kind === "clipboard") {
      root.clipboardQuery = "";
      root.clipboardSelectedIndex = root.filteredClipboardItems.length > 0 ? 0 : -1;
      refreshClipboardList();
      root.activeOverlay = "clipboard";
      Qt.callLater(root.focusClipboard);
    } else {
      root.genericSelectedAction = 0;
      root.genericOverlayTitle = overlayTitle(kind);
      root.genericOverlaySubtitle = "Loading";
      root.genericOverlayRows = [];
      root.genericOverlayActions = [];
      root.genericOverlayError = "";
      root.activeOverlay = kind;
      refreshGenericOverlay(kind);
      Qt.callLater(root.focusGenericOverlay);
    }

    return "ok";
  }

  function closeActiveOverlay() {
    root.activeOverlay = "";
  }

  function focusLauncher() {
    launcherOverlayFocus.forceActiveFocus();
    launcherSearchInput.forceActiveFocus();
  }

  function focusPower() {
    powerOverlayFocus.forceActiveFocus();
  }

  function focusWallpaper() {
    wallpaperOverlayFocus.forceActiveFocus();
    wallpaperSearchInput.forceActiveFocus();
  }

  function focusEmoji() {
    emojiOverlayFocus.forceActiveFocus();
    emojiSearchInput.forceActiveFocus();
  }

  function focusClipboard() {
    clipboardOverlayFocus.forceActiveFocus();
    clipboardSearchInput.forceActiveFocus();
  }

  function focusGenericOverlay() {
    genericOverlayFocus.forceActiveFocus();
  }

  function overlayTitle(kind) {
    var titles = {
      "monitors": "Monitors",
      "stewart": "System",
      "music": "Music",
      "battery": "Battery",
      "calendar": "Calendar",
      "network": "Network",
      "focustime": "Focus Time",
      "volume": "Volume",
      "guide": "Guide",
    };
    return titles[kind] || kind;
  }

  function listText(value) {
    if (!value) {
      return "";
    }
    if (value.join) {
      return value.join(" ");
    }
    return String(value);
  }

  function appSearchText(app) {
    return [
      app.name || "",
      app.genericName || "",
      app.comment || "",
      app.id || "",
      listText(app.categories),
      listText(app.keywords),
    ].join(" ").toLowerCase();
  }

  function compareApps(left, right) {
    var a = (left.name || left.id || "").toLowerCase();
    var b = (right.name || right.id || "").toLowerCase();
    if (a < b) {
      return -1;
    }
    if (a > b) {
      return 1;
    }
    return 0;
  }

  function clampLauncherSelection() {
    if (filteredApps.length === 0) {
      launcherSelectedIndex = -1;
    } else if (launcherSelectedIndex < 0) {
      launcherSelectedIndex = 0;
    } else if (launcherSelectedIndex >= filteredApps.length) {
      launcherSelectedIndex = filteredApps.length - 1;
    }
  }

  function moveLauncherSelection(delta) {
    if (filteredApps.length === 0) {
      return;
    }

    launcherSelectedIndex = Math.max(0, Math.min(filteredApps.length - 1, launcherSelectedIndex + delta));
    launcherList.positionViewAtIndex(launcherSelectedIndex, ListView.Contain);
  }

  function launchApp(index) {
    if (index < 0 || index >= filteredApps.length) {
      return;
    }

    var app = filteredApps[index];

    root.closeActiveOverlay();
    app.execute();
  }

  function handleLauncherKey(event) {
    if (event.key === Qt.Key_Escape) {
      root.closeActiveOverlay();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      launchApp(launcherSelectedIndex);
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      moveLauncherSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      moveLauncherSelection(-1);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageDown) {
      moveLauncherSelection(7);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageUp) {
      moveLauncherSelection(-7);
      event.accepted = true;
    }
  }

  function parsePowerInfo(output) {
    try {
      var payload = JSON.parse(output);
      root.host = payload.host || "Power";
      root.uptime = payload.uptime || "unknown";
    } catch (error) {
      root.host = "Power";
      root.uptime = "unknown";
    }
  }

  function refreshPowerInfo() {
    if (!powerInfoProcess.running) {
      powerInfoProcess.running = true;
    }
  }

  function movePowerSelection(delta) {
    powerSelectedIndex = Math.max(0, Math.min(powerActions.length - 1, powerSelectedIndex + delta));
  }

  function runPowerAction(action) {
    root.closeActiveOverlay();
    Quickshell.execDetached(["qs-power-action", action]);
  }

  function runSelectedPowerAction() {
    runPowerAction(powerActions[powerSelectedIndex].action);
  }

  function handlePowerKey(event) {
    var keyText = event.text.toLowerCase();

    if (event.key === Qt.Key_Escape) {
      root.closeActiveOverlay();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      runSelectedPowerAction();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
      movePowerSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
      movePowerSelection(-1);
      event.accepted = true;
    } else if (keyText === "p") {
      runPowerAction("shutdown");
      event.accepted = true;
    } else if (keyText === "r") {
      runPowerAction("reboot");
      event.accepted = true;
    } else if (keyText === "s") {
      runPowerAction("suspend");
      event.accepted = true;
    } else if (keyText === "l") {
      runPowerAction("logout");
      event.accepted = true;
    }
  }

  function wallpaperListStale() {
    return wallpaperLastLoadMs === 0 || Date.now() - wallpaperLastLoadMs > 60000;
  }

  function refreshWallpaperList() {
    if (!wallpaperListProcess.running) {
      wallpaperListProcess.running = true;
    }
  }

  function parseWallpaperPayload(output) {
    try {
      var payload = JSON.parse(output);
      var parsed = payload.wallpapers || [];

      root.wallpapers = parsed;
      root.wallpaperLastLoadMs = Date.now();
      root.wallpaperSelectedIndex = parsed.length > 0 ? Math.max(0, Math.min(root.wallpaperSelectedIndex, parsed.length - 1)) : -1;
      root.wallpaperErrorText = payload.ok === false ? (payload.error || "Could not read wallpapers") : "";
      root.wallpaperStatusText = parsed.length + " wallpapers";
    } catch (error) {
      root.wallpapers = [];
      root.wallpaperSelectedIndex = -1;
      root.wallpaperErrorText = "Could not parse wallpaper list";
      root.wallpaperStatusText = "0 wallpapers";
    }
  }

  function clampWallpaperSelection() {
    if (filteredWallpapers.length === 0) {
      wallpaperSelectedIndex = -1;
    } else if (wallpaperSelectedIndex < 0) {
      wallpaperSelectedIndex = 0;
    } else if (wallpaperSelectedIndex >= filteredWallpapers.length) {
      wallpaperSelectedIndex = filteredWallpapers.length - 1;
    }
  }

  function moveWallpaperSelection(delta) {
    if (filteredWallpapers.length === 0 || wallpaperApplyProcess.running) {
      return;
    }

    wallpaperSelectedIndex = Math.max(0, Math.min(filteredWallpapers.length - 1, wallpaperSelectedIndex + delta));
    wallpaperGrid.positionViewAtIndex(wallpaperSelectedIndex, GridView.Contain);
  }

  function applySelectedWallpaper() {
    applyWallpaper(wallpaperSelectedIndex);
  }

  function applyWallpaper(index) {
    if (index < 0 || index >= filteredWallpapers.length || wallpaperApplyProcess.running) {
      return;
    }

    wallpaperSelectedIndex = index;
    var wallpaper = filteredWallpapers[index];
    wallpaperApplyProcess.pendingPath = wallpaper.path;
    wallpaperApplyProcess.lastError = "";
    root.wallpaperErrorText = "";
    root.wallpaperStatusText = "Applying " + wallpaper.name;
    wallpaperApplyProcess.command = ["qs-wallpaper-apply", wallpaper.path];
    wallpaperApplyProcess.running = true;
  }

  function handleWallpaperKey(event) {
    if (event.key === Qt.Key_Escape) {
      root.closeActiveOverlay();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.applySelectedWallpaper();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      root.moveWallpaperSelection(wallpaperGrid.columnCount);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      root.moveWallpaperSelection(-wallpaperGrid.columnCount);
      event.accepted = true;
    } else if (event.key === Qt.Key_Right) {
      root.moveWallpaperSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Left) {
      root.moveWallpaperSelection(-1);
      event.accepted = true;
    }
  }

  function wallpaperEmptyText() {
    if (wallpaperListProcess.running && wallpapers.length === 0) {
      return "";
    }
    if (wallpaperErrorText.length > 0 && wallpapers.length === 0) {
      return wallpaperErrorText;
    }
    if (wallpapers.length === 0) {
      return "No wallpapers found";
    }
    return "No matches";
  }

  function pickerSearchText(item) {
    if (!item) {
      return "";
    }

    return [
      item.search || "",
      item.label || "",
      item.description || "",
      item.value || "",
      item.id || "",
      item.line || "",
    ].join(" ").toLowerCase();
  }

  function refreshEmojiList() {
    if (!emojiListProcess.running) {
      emojiListProcess.running = true;
    }
  }

  function parseEmojiPayload(output) {
    try {
      var payload = JSON.parse(output);
      var parsed = payload.items || [];

      root.emojiItems = parsed;
      root.emojiLastLoadMs = Date.now();
      root.emojiSelectedIndex = parsed.length > 0 ? Math.max(0, Math.min(root.emojiSelectedIndex, parsed.length - 1)) : -1;
      root.emojiErrorText = payload.ok === false ? (payload.error || "Could not read emoji") : "";
      root.emojiStatusText = parsed.length + " emoji";
    } catch (error) {
      root.emojiItems = [];
      root.emojiSelectedIndex = -1;
      root.emojiErrorText = "Could not parse emoji list";
      root.emojiStatusText = "0 emoji";
    }
  }

  function clampEmojiSelection() {
    if (filteredEmojiItems.length === 0) {
      emojiSelectedIndex = -1;
    } else if (emojiSelectedIndex < 0) {
      emojiSelectedIndex = 0;
    } else if (emojiSelectedIndex >= filteredEmojiItems.length) {
      emojiSelectedIndex = filteredEmojiItems.length - 1;
    }
  }

  function moveEmojiSelection(delta) {
    if (filteredEmojiItems.length === 0 || emojiApplyProcess.running) {
      return;
    }

    emojiSelectedIndex = Math.max(0, Math.min(filteredEmojiItems.length - 1, emojiSelectedIndex + delta));
    emojiList.positionViewAtIndex(emojiSelectedIndex, ListView.Contain);
  }

  function applySelectedEmoji() {
    applyEmoji(emojiSelectedIndex);
  }

  function applyEmoji(index) {
    if (index < 0 || index >= filteredEmojiItems.length || emojiApplyProcess.running) {
      return;
    }

    emojiSelectedIndex = index;
    var item = filteredEmojiItems[index];
    emojiApplyProcess.pendingLine = item.line || "";
    emojiApplyProcess.lastError = "";
    root.emojiErrorText = "";
    root.emojiStatusText = "Copying " + (item.label || "emoji");
    emojiApplyProcess.command = ["qs-emoji-apply", emojiApplyProcess.pendingLine];
    emojiApplyProcess.running = true;
  }

  function handleEmojiKey(event) {
    if (event.key === Qt.Key_Escape) {
      root.closeActiveOverlay();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.applySelectedEmoji();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      root.moveEmojiSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      root.moveEmojiSelection(-1);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageDown) {
      root.moveEmojiSelection(8);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageUp) {
      root.moveEmojiSelection(-8);
      event.accepted = true;
    }
  }

  function emojiEmptyText() {
    if (emojiListProcess.running && emojiItems.length === 0) {
      return "";
    }
    if (emojiErrorText.length > 0 && emojiItems.length === 0) {
      return emojiErrorText;
    }
    if (emojiItems.length === 0) {
      return "No emoji found";
    }
    return "No matches";
  }

  function refreshClipboardList() {
    if (!clipboardListProcess.running) {
      clipboardListProcess.running = true;
    }
  }

  function parseClipboardPayload(output) {
    try {
      var payload = JSON.parse(output);
      var parsed = payload.items || [];

      root.clipboardItems = parsed;
      root.clipboardLastLoadMs = Date.now();
      root.clipboardSelectedIndex = parsed.length > 0 ? Math.max(0, Math.min(root.clipboardSelectedIndex, parsed.length - 1)) : -1;
      root.clipboardErrorText = payload.ok === false ? (payload.error || "Could not read clipboard history") : "";
      root.clipboardStatusText = parsed.length + " clips";
    } catch (error) {
      root.clipboardItems = [];
      root.clipboardSelectedIndex = -1;
      root.clipboardErrorText = "Could not parse clipboard history";
      root.clipboardStatusText = "0 clips";
    }
  }

  function clampClipboardSelection() {
    if (filteredClipboardItems.length === 0) {
      clipboardSelectedIndex = -1;
    } else if (clipboardSelectedIndex < 0) {
      clipboardSelectedIndex = 0;
    } else if (clipboardSelectedIndex >= filteredClipboardItems.length) {
      clipboardSelectedIndex = filteredClipboardItems.length - 1;
    }
  }

  function moveClipboardSelection(delta) {
    if (filteredClipboardItems.length === 0 || clipboardApplyProcess.running) {
      return;
    }

    clipboardSelectedIndex = Math.max(0, Math.min(filteredClipboardItems.length - 1, clipboardSelectedIndex + delta));
    clipboardList.positionViewAtIndex(clipboardSelectedIndex, ListView.Contain);
  }

  function applySelectedClipboard() {
    applyClipboard(clipboardSelectedIndex);
  }

  function applyClipboard(index) {
    if (index < 0 || index >= filteredClipboardItems.length || clipboardApplyProcess.running) {
      return;
    }

    clipboardSelectedIndex = index;
    var item = filteredClipboardItems[index];
    clipboardApplyProcess.pendingLine = item.line || "";
    clipboardApplyProcess.lastError = "";
    root.clipboardErrorText = "";
    root.clipboardStatusText = "Copying clip";
    clipboardApplyProcess.command = ["qs-clipboard-apply", clipboardApplyProcess.pendingLine];
    clipboardApplyProcess.running = true;
  }

  function handleClipboardKey(event) {
    if (event.key === Qt.Key_Escape) {
      root.closeActiveOverlay();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.applySelectedClipboard();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      root.moveClipboardSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      root.moveClipboardSelection(-1);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageDown) {
      root.moveClipboardSelection(8);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageUp) {
      root.moveClipboardSelection(-8);
      event.accepted = true;
    }
  }

  function clipboardEmptyText() {
    if (clipboardListProcess.running && clipboardItems.length === 0) {
      return "";
    }
    if (clipboardErrorText.length > 0 && clipboardItems.length === 0) {
      return clipboardErrorText;
    }
    if (clipboardItems.length === 0) {
      return "No clipboard history";
    }
    return "No matches";
  }

  function refreshGenericOverlay(kind) {
    if (panelInfoProcess.running) {
      panelInfoProcess.running = false;
    }

    root.pendingGenericKind = kind;
    panelInfoProcess.command = ["qs-panel-info", kind];
    panelInfoProcess.running = true;
  }

  function parseGenericOverlayPayload(output) {
    try {
      var payload = JSON.parse(output);
      root.genericOverlayTitle = payload.title || root.overlayTitle(root.pendingGenericKind);
      root.genericOverlaySubtitle = payload.subtitle || "";
      root.genericOverlayRows = payload.rows || [];
      root.genericOverlayActions = payload.actions || [];
      root.genericOverlayError = payload.error || "";
      root.genericSelectedAction = root.genericOverlayActions.length > 0
        ? Math.max(0, Math.min(root.genericSelectedAction, root.genericOverlayActions.length - 1))
        : -1;
    } catch (error) {
      root.genericOverlayTitle = root.overlayTitle(root.pendingGenericKind);
      root.genericOverlaySubtitle = "";
      root.genericOverlayRows = [];
      root.genericOverlayActions = [];
      root.genericOverlayError = "Could not parse panel data";
      root.genericSelectedAction = -1;
    }
  }

  function runGenericAction(action) {
    if (!action || panelActionProcess.running) {
      return;
    }

    if (action === "focus-toggle") {
      root.toggleFocusTimer();
      return;
    }
    if (action === "focus-reset") {
      root.resetFocusTimer();
      return;
    }

    panelActionProcess.command = ["qs-panel-action", action];
    panelActionProcess.running = true;
  }

  function moveGenericAction(delta) {
    if (root.genericOverlayActions.length === 0) {
      return;
    }

    root.genericSelectedAction = Math.max(0, Math.min(root.genericOverlayActions.length - 1, root.genericSelectedAction + delta));
  }

  function runSelectedGenericAction() {
    if (root.genericSelectedAction < 0 || root.genericSelectedAction >= root.genericOverlayActions.length) {
      return;
    }

    root.runGenericAction(root.genericOverlayActions[root.genericSelectedAction].action);
  }

  function handleGenericKey(event) {
    if (event.key === Qt.Key_Escape) {
      root.closeActiveOverlay();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.runSelectedGenericAction();
      event.accepted = true;
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
      root.moveGenericAction(-1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
      root.moveGenericAction(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_R) {
      root.refreshGenericOverlay(root.activeOverlay);
      event.accepted = true;
    }
  }

  function focusTimeLabel() {
    var minutes = Math.floor(root.focusSecondsRemaining / 60);
    var seconds = root.focusSecondsRemaining % 60;
    var minuteText = minutes < 10 ? "0" + minutes : String(minutes);
    var secondText = seconds < 10 ? "0" + seconds : String(seconds);
    return minuteText + ":" + secondText;
  }

  function toggleFocusTimer() {
    root.focusRunning = !root.focusRunning;
    root.refreshGenericOverlay("focustime");
  }

  function resetFocusTimer() {
    root.focusRunning = false;
    root.focusSecondsRemaining = 25 * 60;
    root.refreshGenericOverlay("focustime");
  }

  onFilteredAppsChanged: clampLauncherSelection()
  onFilteredWallpapersChanged: clampWallpaperSelection()
  onFilteredEmojiItemsChanged: clampEmojiSelection()
  onFilteredClipboardItemsChanged: clampClipboardSelection()

  Component.onCompleted: {
    focusedScreenProcess.running = true;
    refreshPowerInfo();
    refreshWallpaperList();
    refreshEmojiList();
    refreshClipboardList();
  }

  Style {
    id: theme
  }

  IpcHandler {
    target: "quick-actions"

    function activate(kind: string): string {
      return root.activateOverlay(kind);
    }

    function close(): string {
      root.closeActiveOverlay();
      return "ok";
    }
  }

  Process {
    id: focusedScreenProcess

    command: ["qs-focused-screen-watch"]

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        root.updateTrackedScreen(data);
      }
    }

    onExited: function(exitCode, exitStatus) {
      focusedScreenRestartTimer.start();
    }
  }

  Timer {
    id: focusedScreenRestartTimer

    interval: 1000
    repeat: false
    onTriggered: if (!focusedScreenProcess.running) focusedScreenProcess.running = true
  }

  Process {
    id: powerInfoProcess

    command: ["qs-power-info"]

    stdout: StdioCollector {
      onStreamFinished: root.parsePowerInfo(this.text)
    }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.refreshPowerInfo()
  }

  Process {
    id: wallpaperListProcess

    command: ["qs-wallpaper-list"]

    stdout: StdioCollector {
      onStreamFinished: root.parseWallpaperPayload(this.text)
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0) {
          root.wallpaperErrorText = this.text.trim();
        }
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0 && root.wallpapers.length === 0 && root.wallpaperErrorText.length === 0) {
        root.wallpaperErrorText = "Could not list wallpapers";
      }
    }
  }

  Process {
    id: wallpaperApplyProcess

    property string pendingPath: ""
    property string lastError: ""

    stderr: StdioCollector {
      onStreamFinished: wallpaperApplyProcess.lastError = this.text.trim()
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        root.closeActiveOverlay();
      } else {
        root.wallpaperStatusText = root.wallpapers.length + " wallpapers";
        root.wallpaperErrorText = wallpaperApplyProcess.lastError.length > 0 ? wallpaperApplyProcess.lastError : "Failed to apply wallpaper";
        root.focusWallpaper();
      }
    }
  }

  Process {
    id: emojiListProcess

    command: ["qs-emoji-list"]

    stdout: StdioCollector {
      onStreamFinished: root.parseEmojiPayload(this.text)
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0) {
          root.emojiErrorText = this.text.trim();
        }
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0 && root.emojiItems.length === 0 && root.emojiErrorText.length === 0) {
        root.emojiErrorText = "Could not list emoji";
      }
    }
  }

  Process {
    id: emojiApplyProcess

    property string pendingLine: ""
    property string lastError: ""

    stderr: StdioCollector {
      onStreamFinished: emojiApplyProcess.lastError = this.text.trim()
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        root.closeActiveOverlay();
        root.refreshEmojiList();
      } else {
        root.emojiStatusText = root.emojiItems.length + " emoji";
        root.emojiErrorText = emojiApplyProcess.lastError.length > 0 ? emojiApplyProcess.lastError : "Failed to copy emoji";
        root.focusEmoji();
      }
    }
  }

  Process {
    id: clipboardListProcess

    command: ["qs-clipboard-list"]

    stdout: StdioCollector {
      onStreamFinished: root.parseClipboardPayload(this.text)
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0) {
          root.clipboardErrorText = this.text.trim();
        }
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0 && root.clipboardItems.length === 0 && root.clipboardErrorText.length === 0) {
        root.clipboardErrorText = "Could not list clipboard history";
      }
    }
  }

  Process {
    id: clipboardApplyProcess

    property string pendingLine: ""
    property string lastError: ""

    stderr: StdioCollector {
      onStreamFinished: clipboardApplyProcess.lastError = this.text.trim()
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        root.closeActiveOverlay();
        root.refreshClipboardList();
      } else {
        root.clipboardStatusText = root.clipboardItems.length + " clips";
        root.clipboardErrorText = clipboardApplyProcess.lastError.length > 0 ? clipboardApplyProcess.lastError : "Failed to copy clipboard item";
        root.focusClipboard();
      }
    }
  }

  Process {
    id: panelInfoProcess

    stdout: StdioCollector {
      onStreamFinished: root.parseGenericOverlayPayload(this.text)
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0) {
          root.genericOverlayError = this.text.trim();
        }
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0 && root.genericOverlayError.length === 0) {
        root.genericOverlayError = "Could not load panel";
      }
    }
  }

  Process {
    id: panelActionProcess

    onExited: function(exitCode, exitStatus) {
      if (root.genericOverlayActive) {
        root.refreshGenericOverlay(root.activeOverlay);
      }
    }
  }

  Timer {
    interval: 1000
    running: root.focusRunning
    repeat: true
    onTriggered: {
      if (root.focusSecondsRemaining > 0) {
        root.focusSecondsRemaining -= 1;
      }
      if (root.focusSecondsRemaining <= 0) {
        root.focusRunning = false;
      }
    }
  }

  PanelWindow {
    id: launcherWindow

    visible: root.activeOverlay === "launcher"
    screen: root.targetScreen()
    color: "transparent"
    surfaceFormat.opaque: false
    implicitWidth: root.mangoSession ? root.launcherPanelWidth(root.activeScreenWidth()) : 1
    implicitHeight: root.mangoSession ? root.launcherPanelHeight(root.activeScreenHeight()) : 1
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
      left: true
      right: !root.mangoSession
      top: true
      bottom: !root.mangoSession
    }

    margins {
      left: root.mangoSession ? root.centerMarginX(launcherWindow.implicitWidth) : 0
      top: root.mangoSession ? root.centerMarginY(launcherWindow.implicitHeight) : 0
    }

    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) root.focusLauncher()

    Item {
      id: launcherOverlayFocus

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        root.handleLauncherKey(event);
      }

      Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: !root.mangoSession
      }

      MouseArea {
        anchors.fill: parent
        enabled: !root.mangoSession
        visible: !root.mangoSession
        onPressed: launcherSearchInput.forceActiveFocus()
      }

      Rectangle {
        id: launcherPanel

        width: root.mangoSession ? parent.width : root.launcherPanelWidth(parent.width)
        height: root.mangoSession ? parent.height : root.launcherPanelHeight(parent.height)
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 12

          Rectangle {
            id: launcherSearchBox

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: launcherCountLabel.left
            anchors.rightMargin: 10
            height: 42
            color: theme.backgroundAlt
            border.color: launcherSearchInput.activeFocus ? theme.accent : theme.border
            border.width: 1

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              visible: launcherSearchInput.text.length === 0
              text: "Search applications"
              color: theme.muted
              font.family: theme.fontFamily
              font.pixelSize: 14
            }

            TextInput {
              id: launcherSearchInput

              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              text: root.launcherQuery
              color: theme.foreground
              selectionColor: theme.accent
              selectedTextColor: theme.selectedForeground
              clip: true
              font.family: theme.fontFamily
              font.pixelSize: 14
              verticalAlignment: TextInput.AlignVCenter

              onTextChanged: {
                root.launcherQuery = text;
                root.launcherSelectedIndex = root.filteredApps.length > 0 ? 0 : -1;
                if (root.launcherSelectedIndex >= 0) {
                  launcherList.positionViewAtIndex(root.launcherSelectedIndex, ListView.Beginning);
                }
              }

              Keys.onPressed: function(event) {
                root.handleLauncherKey(event);
              }
            }
          }

          Text {
            id: launcherCountLabel

            anchors.top: launcherSearchBox.top
            anchors.right: parent.right
            width: 90
            height: launcherSearchBox.height
            text: root.filteredApps.length + " / " + root.apps.length
            color: theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          ListView {
            id: launcherList

            anchors.top: launcherSearchBox.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: launcherStatusLine.top
            anchors.bottomMargin: 8
            clip: true
            spacing: 5
            model: root.filteredApps
            currentIndex: root.launcherSelectedIndex
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            highlightMoveDuration: 80

            delegate: AppRow {
              width: launcherList.width
              app: modelData
              selected: index === root.launcherSelectedIndex
              onClicked: root.launchApp(index)
            }
          }

          Text {
            anchors.centerIn: launcherList
            width: launcherList.width - 40
            visible: root.filteredApps.length === 0
            text: root.apps.length === 0 ? "No applications found" : "No matches"
            color: theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            id: launcherStatusLine

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 18
            text: "Applications"
            color: theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }
  }

  PanelWindow {
    id: emojiWindow

    visible: root.activeOverlay === "emoji"
    screen: root.targetScreen()
    color: "transparent"
    surfaceFormat.opaque: false
    implicitWidth: root.mangoSession ? root.launcherPanelWidth(root.activeScreenWidth()) : 1
    implicitHeight: root.mangoSession ? root.launcherPanelHeight(root.activeScreenHeight()) : 1
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
      left: true
      right: !root.mangoSession
      top: true
      bottom: !root.mangoSession
    }

    margins {
      left: root.mangoSession ? root.centerMarginX(emojiWindow.implicitWidth) : 0
      top: root.mangoSession ? root.centerMarginY(emojiWindow.implicitHeight) : 0
    }

    WlrLayershell.namespace: "qs-emoji"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) root.focusEmoji()

    Item {
      id: emojiOverlayFocus

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        root.handleEmojiKey(event);
      }

      Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: !root.mangoSession
      }

      MouseArea {
        anchors.fill: parent
        enabled: !root.mangoSession
        visible: !root.mangoSession
        onPressed: emojiSearchInput.forceActiveFocus()
      }

      Rectangle {
        id: emojiPanel

        width: root.mangoSession ? parent.width : root.launcherPanelWidth(parent.width)
        height: root.mangoSession ? parent.height : root.launcherPanelHeight(parent.height)
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 12

          Rectangle {
            id: emojiSearchBox

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: emojiCountLabel.left
            anchors.rightMargin: 10
            height: 42
            color: theme.backgroundAlt
            border.color: emojiSearchInput.activeFocus ? theme.accent : theme.border
            border.width: 1

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              visible: emojiSearchInput.text.length === 0
              text: "Search emoji"
              color: theme.muted
              font.family: theme.fontFamily
              font.pixelSize: 14
            }

            TextInput {
              id: emojiSearchInput

              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              text: root.emojiQuery
              color: theme.foreground
              selectionColor: theme.accent
              selectedTextColor: theme.selectedForeground
              clip: true
              font.family: theme.fontFamily
              font.pixelSize: 14
              verticalAlignment: TextInput.AlignVCenter

              onTextChanged: {
                root.emojiQuery = text;
                root.emojiSelectedIndex = root.filteredEmojiItems.length > 0 ? 0 : -1;
                if (root.emojiSelectedIndex >= 0) {
                  emojiList.positionViewAtIndex(root.emojiSelectedIndex, ListView.Beginning);
                }
              }

              Keys.onPressed: function(event) {
                root.handleEmojiKey(event);
              }
            }
          }

          Text {
            id: emojiCountLabel

            anchors.top: emojiSearchBox.top
            anchors.right: parent.right
            width: 100
            height: emojiSearchBox.height
            text: emojiApplyProcess.running ? "Copying" : (root.filteredEmojiItems.length + " / " + root.emojiItems.length)
            color: emojiApplyProcess.running ? theme.accent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          ListView {
            id: emojiList

            anchors.top: emojiSearchBox.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: emojiStatusLine.top
            anchors.bottomMargin: 8
            clip: true
            spacing: 5
            model: root.filteredEmojiItems
            currentIndex: root.emojiSelectedIndex
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            highlightMoveDuration: 80

            delegate: PickerRow {
              width: emojiList.width
              variant: "emoji"
              label: modelData.label || modelData.value || ""
              description: modelData.description || modelData.line || ""
              selected: index === root.emojiSelectedIndex
              onClicked: root.applyEmoji(index)
            }
          }

          Text {
            anchors.centerIn: emojiList
            width: emojiList.width - 40
            visible: !(emojiListProcess.running && root.emojiItems.length === 0) && root.filteredEmojiItems.length === 0
            text: root.emojiEmptyText()
            color: root.emojiErrorText.length > 0 ? theme.urgent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            id: emojiStatusLine

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 18
            text: root.emojiErrorText.length > 0 ? root.emojiErrorText : root.emojiStatusText
            color: root.emojiErrorText.length > 0 ? theme.urgent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }
  }

  PanelWindow {
    id: clipboardWindow

    visible: root.activeOverlay === "clipboard"
    screen: root.targetScreen()
    color: "transparent"
    surfaceFormat.opaque: false
    implicitWidth: root.mangoSession ? root.launcherPanelWidth(root.activeScreenWidth()) : 1
    implicitHeight: root.mangoSession ? root.launcherPanelHeight(root.activeScreenHeight()) : 1
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
      left: true
      right: !root.mangoSession
      top: true
      bottom: !root.mangoSession
    }

    margins {
      left: root.mangoSession ? root.centerMarginX(clipboardWindow.implicitWidth) : 0
      top: root.mangoSession ? root.centerMarginY(clipboardWindow.implicitHeight) : 0
    }

    WlrLayershell.namespace: "qs-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) root.focusClipboard()

    Item {
      id: clipboardOverlayFocus

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        root.handleClipboardKey(event);
      }

      Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: !root.mangoSession
      }

      MouseArea {
        anchors.fill: parent
        enabled: !root.mangoSession
        visible: !root.mangoSession
        onPressed: clipboardSearchInput.forceActiveFocus()
      }

      Rectangle {
        id: clipboardPanel

        width: root.mangoSession ? parent.width : root.launcherPanelWidth(parent.width)
        height: root.mangoSession ? parent.height : root.launcherPanelHeight(parent.height)
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 12

          Rectangle {
            id: clipboardSearchBox

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: clipboardCountLabel.left
            anchors.rightMargin: 10
            height: 42
            color: theme.backgroundAlt
            border.color: clipboardSearchInput.activeFocus ? theme.accent : theme.border
            border.width: 1

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              visible: clipboardSearchInput.text.length === 0
              text: "Search clipboard"
              color: theme.muted
              font.family: theme.fontFamily
              font.pixelSize: 14
            }

            TextInput {
              id: clipboardSearchInput

              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              text: root.clipboardQuery
              color: theme.foreground
              selectionColor: theme.accent
              selectedTextColor: theme.selectedForeground
              clip: true
              font.family: theme.fontFamily
              font.pixelSize: 14
              verticalAlignment: TextInput.AlignVCenter

              onTextChanged: {
                root.clipboardQuery = text;
                root.clipboardSelectedIndex = root.filteredClipboardItems.length > 0 ? 0 : -1;
                if (root.clipboardSelectedIndex >= 0) {
                  clipboardList.positionViewAtIndex(root.clipboardSelectedIndex, ListView.Beginning);
                }
              }

              Keys.onPressed: function(event) {
                root.handleClipboardKey(event);
              }
            }
          }

          Text {
            id: clipboardCountLabel

            anchors.top: clipboardSearchBox.top
            anchors.right: parent.right
            width: 100
            height: clipboardSearchBox.height
            text: clipboardApplyProcess.running ? "Copying" : (root.filteredClipboardItems.length + " / " + root.clipboardItems.length)
            color: clipboardApplyProcess.running ? theme.accent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          ListView {
            id: clipboardList

            anchors.top: clipboardSearchBox.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: clipboardStatusLine.top
            anchors.bottomMargin: 8
            clip: true
            spacing: 5
            model: root.filteredClipboardItems
            currentIndex: root.clipboardSelectedIndex
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            highlightMoveDuration: 80

            delegate: PickerRow {
              width: clipboardList.width
              variant: "clipboard"
              label: modelData.label || modelData.line || ""
              description: modelData.description || ""
              selected: index === root.clipboardSelectedIndex
              onClicked: root.applyClipboard(index)
            }
          }

          Text {
            anchors.centerIn: clipboardList
            width: clipboardList.width - 40
            visible: !(clipboardListProcess.running && root.clipboardItems.length === 0) && root.filteredClipboardItems.length === 0
            text: root.clipboardEmptyText()
            color: root.clipboardErrorText.length > 0 ? theme.urgent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            id: clipboardStatusLine

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 18
            text: root.clipboardErrorText.length > 0 ? root.clipboardErrorText : root.clipboardStatusText
            color: root.clipboardErrorText.length > 0 ? theme.urgent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }
  }

  PanelWindow {
    id: powerWindow

    visible: root.activeOverlay === "power"
    screen: root.targetScreen()
    color: "transparent"
    surfaceFormat.opaque: false
    implicitWidth: root.mangoSession ? root.powerPanelWidth(root.activeScreenWidth()) : 1
    implicitHeight: root.mangoSession ? root.powerPanelHeight(root.activeScreenHeight()) : 1
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
      left: true
      right: !root.mangoSession
      top: true
      bottom: !root.mangoSession
    }

    margins {
      left: root.mangoSession ? root.centerMarginX(powerWindow.implicitWidth) : 0
      top: root.mangoSession ? root.centerMarginY(powerWindow.implicitHeight) : 0
    }

    WlrLayershell.namespace: "qs-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) root.focusPower()

    Item {
      id: powerOverlayFocus

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        root.handlePowerKey(event);
      }

      Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: !root.mangoSession
      }

      MouseArea {
        anchors.fill: parent
        enabled: !root.mangoSession
        visible: !root.mangoSession
        onPressed: powerOverlayFocus.forceActiveFocus()
      }

      Rectangle {
        id: powerPanel

        width: root.mangoSession ? parent.width : root.powerPanelWidth(parent.width)
        height: root.mangoSession ? parent.height : root.powerPanelHeight(parent.height)
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 12

          Rectangle {
            id: powerTitleBlock

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 78
            color: theme.backgroundAlt
            border.color: theme.border
            border.width: 1

            Rectangle {
              id: powerIcon

              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              width: 42
              height: 42
              color: theme.urgent

              Text {
                anchors.centerIn: parent
                text: "Power"
                color: theme.selectedForeground
                font.family: theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
            }

            Text {
              id: hostLabel

              anchors.left: powerIcon.right
              anchors.leftMargin: 12
              anchors.right: parent.right
              anchors.rightMargin: 12
              anchors.top: parent.top
              anchors.topMargin: 15
              text: root.host
              color: theme.foreground
              font.family: theme.fontFamily
              font.pixelSize: 15
              elide: Text.ElideRight
            }

            Text {
              anchors.left: hostLabel.left
              anchors.right: hostLabel.right
              anchors.top: hostLabel.bottom
              anchors.topMargin: 6
              text: "Uptime: " + root.uptime
              color: theme.muted
              font.family: theme.fontFamily
              font.pixelSize: 12
              elide: Text.ElideRight
            }
          }

          ListView {
            id: powerList

            anchors.top: powerTitleBlock.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            spacing: 5
            model: root.powerActions
            currentIndex: root.powerSelectedIndex
            interactive: false

            delegate: Item {
              width: powerList.width
              height: 52

              Rectangle {
                anchors.fill: parent
                color: index === root.powerSelectedIndex ? theme.accent : (powerActionMouse.containsMouse ? theme.backgroundAlt : "transparent")
                border.color: index === root.powerSelectedIndex ? theme.accent : theme.border
                border.width: index === root.powerSelectedIndex || powerActionMouse.containsMouse ? 1 : 0
              }

              Item {
                id: powerActionIcon

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 74
                height: parent.height

                Image {
                  id: powerActionIconSource

                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  width: 18
                  height: 18
                  sourceSize.width: 18
                  sourceSize.height: 18
                  fillMode: Image.PreserveAspectFit
                  source: modelData.icon
                  visible: false
                }

                MultiEffect {
                  anchors.fill: powerActionIconSource
                  source: powerActionIconSource
                  colorization: 1.0
                  colorizationColor: index === root.powerSelectedIndex || powerActionMouse.containsMouse
                    ? theme.selectedForeground
                    : theme.foreground
                }
              }

              Text {
                anchors.left: powerActionIcon.right
                anchors.right: powerShortcutLabel.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: index === root.powerSelectedIndex ? theme.selectedForeground : theme.foreground
                font.family: theme.fontFamily
                font.pixelSize: 14
                elide: Text.ElideRight
              }

              Text {
                id: powerShortcutLabel

                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                text: modelData.shortcut
                color: index === root.powerSelectedIndex ? theme.selectedForeground : theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
              }

              MouseArea {
                id: powerActionMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runPowerAction(modelData.action)
                onEntered: root.powerSelectedIndex = index
              }
            }
          }
        }
      }
    }
  }

  PanelWindow {
    id: wallpaperWindow

    visible: root.activeOverlay === "wallpaper"
    screen: root.targetScreen()
    color: "transparent"
    surfaceFormat.opaque: false
    implicitWidth: root.mangoSession ? root.wallpaperPanelWidth(root.activeScreenWidth()) : 1
    implicitHeight: root.mangoSession ? root.wallpaperPanelHeight(root.activeScreenHeight()) : 1
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
      left: true
      right: !root.mangoSession
      top: true
      bottom: !root.mangoSession
    }

    margins {
      left: root.mangoSession ? root.centerMarginX(wallpaperWindow.implicitWidth) : 0
      top: root.mangoSession ? root.centerMarginY(wallpaperWindow.implicitHeight) : 0
    }

    WlrLayershell.namespace: "qs-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) root.focusWallpaper()

    Item {
      id: wallpaperOverlayFocus

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        root.handleWallpaperKey(event);
      }

      Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: !root.mangoSession
      }

      MouseArea {
        anchors.fill: parent
        enabled: !root.mangoSession
        visible: !root.mangoSession
        onPressed: wallpaperSearchInput.forceActiveFocus()
      }

      Rectangle {
        id: wallpaperPanel

        width: root.mangoSession ? parent.width : root.wallpaperPanelWidth(parent.width)
        height: root.mangoSession ? parent.height : root.wallpaperPanelHeight(parent.height)
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 14

          Rectangle {
            id: wallpaperSearchBox

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: wallpaperCountLabel.left
            anchors.rightMargin: 12
            height: 42
            color: theme.backgroundAlt
            border.color: wallpaperSearchInput.activeFocus ? theme.accent : theme.border
            border.width: 1

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              visible: wallpaperSearchInput.text.length === 0
              text: "Search wallpapers"
              color: theme.muted
              font.family: theme.fontFamily
              font.pixelSize: 14
            }

            TextInput {
              id: wallpaperSearchInput

              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              text: root.wallpaperQuery
              color: theme.foreground
              selectionColor: theme.accent
              selectedTextColor: theme.selectedForeground
              clip: true
              font.family: theme.fontFamily
              font.pixelSize: 14
              verticalAlignment: TextInput.AlignVCenter

              onTextChanged: {
                root.wallpaperQuery = text;
                root.wallpaperSelectedIndex = root.filteredWallpapers.length > 0 ? 0 : -1;
                if (root.wallpaperSelectedIndex >= 0) {
                  wallpaperGrid.positionViewAtIndex(root.wallpaperSelectedIndex, GridView.Beginning);
                }
              }

              Keys.onPressed: function(event) {
                root.handleWallpaperKey(event);
              }
            }
          }

          Text {
            id: wallpaperCountLabel

            anchors.top: wallpaperSearchBox.top
            anchors.right: parent.right
            width: 150
            height: wallpaperSearchBox.height
            text: wallpaperApplyProcess.running ? "Applying" : (root.filteredWallpapers.length + " / " + root.wallpapers.length)
            color: wallpaperApplyProcess.running ? theme.accent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          GridView {
            id: wallpaperGrid

            property int columnCount: Math.max(2, Math.floor(width / 155))

            anchors.top: wallpaperSearchBox.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: wallpaperStatusLine.top
            anchors.bottomMargin: 10
            clip: true
            model: root.filteredWallpapers
            currentIndex: root.wallpaperSelectedIndex
            cellWidth: width / columnCount
            cellHeight: 142
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            highlightMoveDuration: 80

            delegate: WallpaperCard {
              width: wallpaperGrid.cellWidth - 8
              height: wallpaperGrid.cellHeight - 8
              fileName: modelData.name
              imageSource: modelData.thumbUrl
              selected: index === root.wallpaperSelectedIndex
              busy: wallpaperApplyProcess.running && wallpaperApplyProcess.pendingPath === modelData.path

              onClicked: root.applyWallpaper(index)
            }
          }

          Text {
            anchors.centerIn: wallpaperGrid
            width: wallpaperGrid.width - 40
            visible: !(wallpaperListProcess.running && root.wallpapers.length === 0) && root.filteredWallpapers.length === 0
            text: root.wallpaperEmptyText()
            color: root.wallpaperErrorText.length > 0 ? theme.urgent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            id: wallpaperStatusLine

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 20
            text: root.wallpaperErrorText.length > 0 ? root.wallpaperErrorText : root.wallpaperStatusText
            color: root.wallpaperErrorText.length > 0 ? theme.urgent : theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }
  }

  PanelWindow {
    id: genericWindow

    visible: root.genericOverlayActive
    screen: root.targetScreen()
    color: "transparent"
    surfaceFormat.opaque: false
    implicitWidth: root.mangoSession ? root.genericPanelWidth(root.activeScreenWidth()) : 1
    implicitHeight: root.mangoSession ? root.genericPanelHeight(root.activeScreenHeight()) : 1
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
      left: true
      right: !root.mangoSession
      top: true
      bottom: !root.mangoSession
    }

    margins {
      left: root.mangoSession ? root.centerMarginX(genericWindow.implicitWidth) : 0
      top: root.mangoSession ? root.centerMarginY(genericWindow.implicitHeight) : 0
    }

    WlrLayershell.namespace: "qs-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) root.focusGenericOverlay()

    Item {
      id: genericOverlayFocus

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        root.handleGenericKey(event);
      }

      Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: !root.mangoSession
      }

      MouseArea {
        anchors.fill: parent
        enabled: !root.mangoSession
        visible: !root.mangoSession
        onPressed: genericOverlayFocus.forceActiveFocus()
      }

      Rectangle {
        id: genericPanel

        width: root.mangoSession ? parent.width : root.genericPanelWidth(parent.width)
        height: root.mangoSession ? parent.height : root.genericPanelHeight(parent.height)
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 14

          Text {
            id: genericTitle

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 26
            text: root.genericOverlayTitle
            color: theme.foreground
            font.family: theme.fontFamily
            font.pixelSize: 16
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }

          Rectangle {
            id: genericStatus

            anchors.top: genericTitle.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            color: theme.backgroundAlt
            border.color: root.genericOverlayError.length > 0 ? theme.urgent : theme.border
            border.width: 1

            Text {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              text: root.activeOverlay === "focustime"
                ? (root.focusRunning ? "Focused: " : "Ready: ") + root.focusTimeLabel()
                : (root.genericOverlayError.length > 0 ? root.genericOverlayError : root.genericOverlaySubtitle)
              color: root.genericOverlayError.length > 0 ? theme.urgent : theme.foreground
              font.family: theme.fontFamily
              font.pixelSize: root.activeOverlay === "focustime" ? 20 : 13
              font.bold: root.activeOverlay === "focustime"
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
            }
          }

          ListView {
            id: genericRows

            anchors.top: genericStatus.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: genericActions.top
            anchors.bottomMargin: 10
            clip: true
            spacing: 4
            model: root.genericOverlayRows
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              width: genericRows.width
              height: Math.max(34, rowValue.implicitHeight + 12)
              color: index % 2 === 0 ? "transparent" : theme.backgroundAlt
              border.color: "transparent"
              border.width: 0

              Text {
                id: rowLabel

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(150, parent.width * 0.36)
                text: modelData.label || ""
                color: theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
              }

              Text {
                id: rowValue

                anchors.left: rowLabel.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.value || ""
                color: theme.foreground
                font.family: theme.fontFamily
                font.pixelSize: 13
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
              }
            }
          }

          Text {
            anchors.centerIn: genericRows
            visible: !panelInfoProcess.running && root.genericOverlayRows.length === 0 && root.genericOverlayError.length === 0
            text: "No data"
            color: theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 14
          }

          Row {
            id: genericActions

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 38
            spacing: 6

            Repeater {
              model: root.genericOverlayActions

              delegate: Rectangle {
                width: Math.max(74, actionText.implicitWidth + 22)
                height: 34
                color: index === root.genericSelectedAction ? theme.accent : (actionMouse.containsMouse ? theme.backgroundAlt : "transparent")
                border.color: index === root.genericSelectedAction || actionMouse.containsMouse ? theme.accent : theme.border
                border.width: 1

                Text {
                  id: actionText

                  anchors.centerIn: parent
                  text: modelData.action === "focus-toggle"
                    ? (root.focusRunning ? "Pause" : "Start")
                    : (modelData.label || "")
                  color: index === root.genericSelectedAction ? theme.selectedForeground : theme.foreground
                  font.family: theme.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  elide: Text.ElideRight
                }

                MouseArea {
                  id: actionMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.genericSelectedAction = index
                  onClicked: root.runGenericAction(modelData.action)
                }
              }
            }
          }
        }
      }
    }
  }
}

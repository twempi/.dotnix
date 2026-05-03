{...}: {
  wayland.windowManager.mango.settings = {
    env = [
      "WLR_DRM_NO_ATOMIC,1"
      "WLR_RENDERER_ALLOW_SOFTWARE,1"
      "WLR_USE_LIBINPUT,1"
      "WLR_NO_HARDWARE_CURSORS,1"
      "XDG_SESSION_TYPE,wayland"
      "XDG_SESSION_DESKTOP,Mango"
      "XCURSOR_SIZE,24"
      "QT_QPA_PLATFORM,wayland"
    ];
  };
}

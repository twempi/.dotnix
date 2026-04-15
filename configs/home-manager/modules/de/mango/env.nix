{...}: {
  xdg.configFile."mango/conf.d/env.conf".text = ''
    env=WLR_DRM_NO_ATOMIC,1
    env=WLR_RENDERER_ALLOW_SOFTWARE,1
    env=WLR_USE_LIBINPUT,1
    env=WLR_NO_HARDWARE_CURSORS,1
    env=XDG_SESSION_TYPE,wayland
    env=XDG_SESSION_DESKTOP,Mango
    env=XCURSOR_SIZE,24
    env=QT_QPA_PLATFORM,wayland
  '';
}

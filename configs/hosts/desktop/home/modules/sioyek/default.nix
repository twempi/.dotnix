{
  flake.modules.homeManager.desktop-sioyek = {pkgs, ...}: {
    # On Wayland, NVIDIA EGL makes Qt default to an OpenGL ES context. Sioyek asks
    # for a 3.3 core context without choosing desktop GL, so eglCreateContext fails
    # with EGL_BAD_MATCH (3009) and no window is ever mapped. GLX under XWayland
    # gets desktop GL.
    programs.sioyek.package = pkgs.symlinkJoin {
      name = "sioyek-xcb";
      paths = [pkgs.sioyek];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/sioyek --set QT_QPA_PLATFORM xcb
      '';
    };
  };
}

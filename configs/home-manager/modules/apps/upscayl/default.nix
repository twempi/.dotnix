{
  home.file.".local/share/applications/upscayl.desktop".text = ''
    [Desktop Entry]
    Name=Upscayl
    Exec=env -u GBM_BACKEND -u __GLX_VENDOR_LIBRARY_NAME -u LIBVA_DRIVER_NAME upscayl --ozone-platform=x11
    Terminal=false
    Type=Application
    Icon=upscayl
    StartupWMClass=Upscayl
    X-AppImage-Version=2.15.0
    Comment=Free and Open Source AI Image Upscaler
    Categories=Graphics;2DGraphics;RasterGraphics;ImageProcessing;
  '';
}

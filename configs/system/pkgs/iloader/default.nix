{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  glib,
  gtk3,
  gdk-pixbuf,
  cairo,
  pango,
  atk,
  harfbuzz,
  openssl,
  libayatana-appindicator,
  webkitgtk_4_1,
  libsoup_3,
  librsvg,
  xorg,
  libGL,
  mesa,
  alsa-lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "iloader";
  version = "2.0.10";

  src = fetchurl {
    url = "https://github.com/nab138/iloader/releases/download/v${version}/iloader-linux-amd64.deb";
    # replace after first build attempt with the real hash from nix
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    glib
    gtk3
    gdk-pixbuf
    cairo
    pango
    atk
    harfbuzz
    openssl
    libayatana-appindicator
    webkitgtk_4_1
    libsoup_3
    librsvg
    libGL
    mesa
    alsa-lib
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXext
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/

    if [ -f "$out/bin/iloader" ]; then
      chmod +x "$out/bin/iloader"
    fi

    if [ -f "$out/share/applications/iloader.desktop" ]; then
      substituteInPlace "$out/share/applications/iloader.desktop" \
        --replace-fail "/usr/bin/iloader" "$out/bin/iloader"
    fi

    wrapProgram "$out/bin/iloader" \
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
      --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libGL mesa]}"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "iloader";
      desktopName = "iLoader";
      exec = "iloader";
      terminal = false;
      categories = ["Utility"];
    })
  ];

  meta = with lib; {
    description = "User friendly sideloader";
    homepage = "https://iloader.app/";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "iloader";
  };
}

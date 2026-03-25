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
  libGL,
  mesa,
  alsa-lib,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxext,
  libxfixes,
  libxcomposite,
  libxdamage,
  libxrender,
  libxtst,
  libxcb,
}:
stdenvNoCC.mkDerivation rec {
  pname = "iloader";
  version = "2.0.10";

  src = fetchurl {
    url = "https://github.com/nab138/iloader/releases/download/v${version}/iloader-linux-amd64.deb";
    hash = "sha256-m/1M8IfC3e6mAIZ0z7kKfnTgSsO75YSwdHh2kVJov7s=";
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
    libx11
    libxcursor
    libxi
    libxrandr
    libxext
    libxfixes
    libxcomposite
    libxdamage
    libxrender
    libxtst
    libxcb
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
      sed -i "s|^Exec=.*|Exec=$out/bin/iloader|" \
        "$out/share/applications/iloader.desktop"
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
    platforms = [stdenvNoCC.hostPlatform.system];
    mainProgram = "iloader";
  };
}

{
  lib,
  appimageTools,
  fetchurl,
  wtype,
  xdotool,
}:
let
  pname = "handy";
  version = "0.9.5";

  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
    hash = "sha256-u6HXEDrMMO8DRpcK8sHYh13zI40dZbelv1oOSKGn7Zw=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [
    wtype
    xdotool
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/usr/share/applications/Handy.desktop \
      "$out/share/applications/handy.desktop"
    substituteInPlace "$out/share/applications/handy.desktop" \
      --replace-fail "Exec=handy" "Exec=$out/bin/handy"

    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/32x32/apps/handy.png \
      "$out/share/icons/hicolor/32x32/apps/handy.png"
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/128x128/apps/handy.png \
      "$out/share/icons/hicolor/128x128/apps/handy.png"
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/256x256@2/apps/handy.png \
      "$out/share/icons/hicolor/256x256@2/apps/handy.png"
  '';

  meta = with lib; {
    description = "A free, open source, and extensible speech-to-text application that works completely offline";
    homepage = "https://handy.computer/";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "handy";
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
}

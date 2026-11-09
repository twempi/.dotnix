{
  lib,
  pkgs,
}:
# Accepts an unpacked directory or a CRX. Firefox has no background service
# workers or side panels, so those become MV3 event pages and sidebars.
{
  id,
  src,
  manifestPatch ? ".",
}:
pkgs.runCommand "librewolf-extension-${id}.xpi" {
  nativeBuildInputs = [pkgs.jq pkgs.unzip pkgs.zip];
} ''
  mkdir ext
  if [ -d ${src} ]; then
    cp -r --no-preserve=mode ${src}/. ext/
  else
    # unzip exits non-zero on the bytes of the CRX header.
    unzip -q ${src} -d ext || test -f ext/manifest.json
  fi

  jq --arg id ${lib.escapeShellArg id} '
    .browser_specific_settings.gecko.id = $id
    | if .background.service_worker then
        .background.scripts = [.background.service_worker] | del(.background.service_worker)
      else . end
    | if .side_panel.default_path then
        .sidebar_action = {default_panel: .side_panel.default_path, open_at_install: false}
      else . end
    | ${manifestPatch}
  ' ext/manifest.json > manifest.json
  mv manifest.json ext/manifest.json

  cd ext
  zip -qrX "$out" .
''

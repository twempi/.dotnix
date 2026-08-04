{
  lib,
  pkgs,
  ...
}: let
  braveWithWaylandFlags = pkgs.brave.overrideAttrs (old: {
    preFixup = (old.preFixup or "") + ''
      gappsWrapperArgs+=(
        --add-flags "--enable-features=UseOzonePlatform"
        --add-flags "--ozone-platform=wayland"
        --add-flags "--disable-features=WaylandFractionalScaleV1"
      )
    '';
  });
in {
  programs.chromium = {
    enable = true;
    package = braveWithWaylandFlags;
    commandLineArgs = lib.mkForce [];
    extensions = [
      {id = "cndibmoanboadcifjkjbdpjgfedanolh";} # better canvas
      {id = "fcjmgeodgobggcppooncdagfkogfffdm";} # imagus reborn
      {id = "edibdbjcniadpccecjdfdjjppcpchdlm";} # i still dont care about cookies
      {id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp";} # privacy badger
      {id = "hlepfoohegkhhmjieoechaddaejaokhf";} # refined github
      {id = "kabafodfnabokkkddjbnkgbcbmipdlmb";} # tasks for canvas
      {id = "khncfooichmfjbepaaaebmommgaepoid";} # unhook for youtube
      {id = "ihgeijoonjmdfkamhpgoedplnmbencgd";} # UnInternet
      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";} # vimium
      {id = "oldceeleldhonbafppcapldpdifcinji";} # ai grammer checker
    ];
  };
}

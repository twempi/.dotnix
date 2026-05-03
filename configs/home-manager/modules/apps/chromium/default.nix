{
  pkgs,
  ...
}: {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
      "--disable-features=WaylandFractionalScaleV1"
    ];
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

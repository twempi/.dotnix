{pkgs, ...}: let
  RARS = ./myapp.jar;
in {
  home.packages = [
    (pkgs.writeShellScriptBin "RARS" ''
      export GTK_APPLICATION_PREFER_DARK_THEME=0
      unset GTK_THEME
      unset QT_STYLE_OVERRIDE
      exec ${pkgs.jre}/bin/java -jar ${RARS} "$@"
    '')
  ];

  xdg.desktopEntries.myapp = {
    name = "RARS 1.55";
    comment = "My Java application";
    exec = "RARS";
    terminal = false;
    categories = ["Utility"];
  };
}

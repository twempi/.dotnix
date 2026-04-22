{...}: {
  stylix.targets.obsidian = {
    enable = true;
    vaultNames = ["notes"];
    fonts.enable = false;
  };

  programs.obsidian = {
    enable = true;

    vaults.notes = {
      target = "Documents/notes";

      settings = {
        app = {
          promptDelete = false;
          vimMode = true;
          showLineNumber = true;
          readableLineLength = false;
          attachmentFolderPath = "999 Images";
          newFileLocation = "folder";
          alwaysUpdateLinks = true;
          strictLineBreaks = false;
          newFileFolderPath = "000 Index";
          showInlineTitle = true;

          pdfExportSettings = {
            includeName = false;
            pageSize = "Letter";
            landscape = false;
            margin = "0";
            downscalePercent = 100;
          };

          openBehavior = "";
          spellcheck = true;
          focusNewTab = false;
        };

        appearance = {
          theme = "obsidian";
          cssTheme = "";
          accentColor = "";
          nativeMenus = false;
          interfaceFontFamily = "Source Code Pro";
          textFontFamily = "Source Code Pro";
          monospaceFontFamily = "Source Code Pro";
          showViewHeader = true;
        };

        cssSnippets = [
          ./snippets/DV-Button.css
          ./snippets/Hide-Properties-Class.css
          ./snippets/mathjax-font.css
          ./snippets/Tags-Edit.css
        ];
      };
    };
  };
}

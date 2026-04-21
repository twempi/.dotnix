{hostname, ...}: let
  isDesktop = hostname == "desktop";

  notesTarget =
    if isDesktop
    then "/mnt/Storage/Documents/notes"
    else "Documents/notes";
in {
  stylix.targets.obsidian = {
    enable = true;
    vaultNames = ["notes"];
  };

  programs.obsidian = {
    enable = true;
    vaults.notes.target = notesTarget;
  };
}

{ pkgs, ... }:

{
  programs.obsidian = {
    enable = true;
    package = pkgs.obsidian;
  };

  xdg.desktopEntries.obsidian = {
    name = "Obsidian";
    comment = "Knowledge base";
    exec = "obsidian %U";
    icon = "obsidian";
    categories = [ "Office" ];
    mimeType = [ "x-scheme-handler/obsidian" ];
    startupNotify = true;
    terminal = false;
  };
}

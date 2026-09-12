{ pkgs, ... }:

{
  home.packages = [ pkgs.zotero ];

  xdg.desktopEntries.zotero = {
    name = "Zotero";
    genericName = "Reference Manager";
    comment = "Collect, organize and cite research";
    exec = "zotero %U";
    icon = "zotero";
    categories = [
      "Office"
      "Education"
      "Science"
    ];
    mimeType = [
      "x-scheme-handler/zotero"
      "text/x-bibtex"
      "application/x-research-info-systems"
    ];
    startupNotify = true;
    terminal = false;
  };
}

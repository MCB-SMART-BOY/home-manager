{ pkgs, ... }:

{
  home.packages = [ pkgs.sioyek ];

  xdg.desktopEntries.sioyek = {
    name = "Sioyek";
    genericName = "PDF Viewer";
    comment = "PDF viewer optimized for research papers";
    exec = "sioyek %U";
    icon = "sioyek";
    categories = [
      "Office"
      "Viewer"
    ];
    mimeType = [
      "application/pdf"
      "application/postscript"
    ];
    startupNotify = true;
    terminal = false;
  };
}

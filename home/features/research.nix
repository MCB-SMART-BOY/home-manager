{ pkgs, ... }:

{
  home.packages = with pkgs; [
    sioyek
    zotero
    pandoc
    typst
    texstudio
    (texlive.withPackages (ps: [ ps.scheme-medium ]))
    biber
    qpdf
    poppler-utils
    obsidian
    libreoffice-still
    xournalpp
    goldendict-ng
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "sioyek.desktop" ];
      "application/postscript" = [ "sioyek.desktop" ];
      "application/msword" = [ "libreoffice-writer.desktop" ];
      "application/rtf" = [ "libreoffice-writer.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
        "libreoffice-writer.desktop"
      ];
      "application/vnd.oasis.opendocument.text" = [ "libreoffice-writer.desktop" ];
      "application/vnd.ms-excel" = [ "libreoffice-calc.desktop" ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
        "libreoffice-calc.desktop"
      ];
      "application/vnd.oasis.opendocument.spreadsheet" = [ "libreoffice-calc.desktop" ];
      "application/vnd.ms-powerpoint" = [ "libreoffice-impress.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
        "libreoffice-impress.desktop"
      ];
      "application/vnd.oasis.opendocument.presentation" = [ "libreoffice-impress.desktop" ];
      "x-scheme-handler/zotero" = [ "zotero.desktop" ];
      "text/x-bibtex" = [ "zotero.desktop" ];
      "application/x-research-info-systems" = [ "zotero.desktop" ];
    };
  };

  xdg.desktopEntries = {
    sioyek = {
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
    zotero = {
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
    obsidian = {
      name = "Obsidian";
      comment = "Knowledge base";
      exec = "obsidian %U";
      icon = "obsidian";
      categories = [ "Office" ];
      mimeType = [ "x-scheme-handler/obsidian" ];
      startupNotify = true;
      terminal = false;
    };
  };
}

{ pkgs, ... }:

{
  imports = [
    ../config/sioyek
    ../config/zotero
    ../config/obsidian
  ];

  programs = {
    libreoffice = {
      enable = true;
      package = pkgs.libreoffice-still;
    };
    pandoc.enable = true;
  };

  home.packages = with pkgs; [
    typst
    texstudio
    (texlive.withPackages (ps: [ ps.scheme-medium ]))
    biber
    qpdf
    poppler-utils
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
}

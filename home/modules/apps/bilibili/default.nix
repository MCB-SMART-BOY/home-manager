{ pkgs, ... }:

{
  home.packages = [ pkgs.bilibili ];

  xdg.desktopEntries."io.github.msojocs.bilibili" = {
    name = "Bilibili";
    comment = "Bilibili Desktop";
    exec = "bilibili %U";
    icon = "io.github.msojocs.bilibili";
    categories = [
      "AudioVideo"
      "Video"
      "TV"
    ];
    settings.Keywords = "bilibili;b站;视频;动漫;";
    terminal = false;
  };
}

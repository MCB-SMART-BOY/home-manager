{ pkgs, ... }:

{
  home.packages = [ pkgs.clash-verge-rev ];

  xdg.desktopEntries."clash-verge" = {
    name = "Clash Verge";
    comment = "Clash Verge Rev";
    exec = "clash-verge %U";
    icon = "clash-verge";
    categories = [ "Development" ];
    mimeType = [ "x-scheme-handler/clash" ];
    startupNotify = true;
    terminal = false;
  };
}

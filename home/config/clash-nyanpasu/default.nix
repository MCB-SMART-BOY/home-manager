{ pkgs, ... }:

{
  home.packages = [ pkgs.clash-nyanpasu ];

  xdg.desktopEntries."clash-nyanpasu" = {
    name = "Clash Nyanpasu";
    comment = "Clash Nyanpasu! (∠・ω< )⌒☆";
    exec = "clash-nyanpasu";
    icon = "clash-nyanpasu";
    categories = [ "Development" ];
    startupNotify = true;
    terminal = false;
  };
}

{ pkgs, ... }:

{
  home.packages = [
    pkgs.adwaita-icon-theme
    pkgs.gnome-themes-extra
    (pkgs.tela-circle-icon-theme.override { colorVariants = [ "dracula" ]; })
    pkgs.catppuccin-cursors.mochaMauve
    pkgs.nwg-look
  ];

  xdg.dataFile = {
    "themes/Catppuccin-Purple-Dark-Catppuccin" = {
      source = ../../assets/themes/Catppuccin-Purple-Dark-Catppuccin;
      recursive = true;
    };
    "themes/Catppuccin-Purple-Dark-Catppuccin-hdpi" = {
      source = ../../assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi;
      recursive = true;
    };
    "themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi" = {
      source = ../../assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi;
      recursive = true;
    };
  };
}

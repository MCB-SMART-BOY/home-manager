{ pkgs, ... }:

{
  home.packages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
    (tela-circle-icon-theme.override { colorVariants = [ "dracula" ]; })
    nwg-look
  ];

  gtk = {
    enable = true;
    theme.name = "Catppuccin-Purple-Dark-Catppuccin";
    iconTheme.name = "Tela-circle-dracula-dark";
    cursorTheme = {
      name = "Catppuccin-Mocha-Mauve-Cursors";
      size = 24;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk2.extraConfig = ''
      gtk-im-module="fcitx"
    '';
  };

  xdg.dataFile = {
    "themes/Catppuccin-Purple-Dark-Catppuccin" = {
      source = ../assets/themes/Catppuccin-Purple-Dark-Catppuccin;
      recursive = true;
    };
    "themes/Catppuccin-Purple-Dark-Catppuccin-hdpi" = {
      source = ../assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi;
      recursive = true;
    };
    "themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi" = {
      source = ../assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi;
      recursive = true;
    };
    "icons/Catppuccin-Mocha-Mauve-Cursors" = {
      source = ../assets/themes/Catppuccin-Mocha-Mauve-Cursors;
      recursive = true;
    };
  };
}

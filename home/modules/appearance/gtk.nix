let
  cursorName = "catppuccin-mocha-mauve-cursors";
in
{
  gtk = {
    enable = true;
    theme.name = "Catppuccin-Purple-Dark-Catppuccin";
    iconTheme.name = "Tela-circle-dracula-dark";
    cursorTheme = {
      name = cursorName;
      size = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-name = cursorName;
    };
  };
}

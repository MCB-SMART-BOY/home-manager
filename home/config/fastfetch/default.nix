{ ... }:

{
  programs.fastfetch.enable = true;

  xdg.configFile."fastfetch/config.jsonc".source = ./mokka.jsonc;

  home.file = {
    ".local/share/fastfetch/logos/logo-01.png".source = ./assets/fastfetch-logos/logo-01.png;
    ".local/share/fastfetch/logos/logo-02.png".source = ./assets/fastfetch-logos/logo-02.png;
    ".local/share/fastfetch/logos/logo-03.webp".source = ./assets/fastfetch-logos/logo-03.webp;
  };
}

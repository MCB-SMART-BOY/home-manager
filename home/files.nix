{ ... }:

{
  xdg.configFile = {
    "toolchain/tools.json".source = ./config/toolchain/tools.json;
    "btop/btop.conf".source = ./config/btop/btop.conf;
    "btop/themes/noctalia.theme".source = ./config/btop/themes/noctalia.theme;
    "fastfetch/config.jsonc".source = ./config/fastfetch/mokka.jsonc;
    "kitty/kitty.conf".source = ./config/kitty/kitty.conf;
    "helix/config.toml".source = ./config/helix/config.toml;
    "helix/languages.toml".source = ./config/helix/languages.toml;
    "clangd/config.yaml".source = ./config/clangd/config.yaml;
  };

  home.file = {
    ".local/share/fastfetch/logos/logo-01.png".source = ./assets/fastfetch-logos/logo-01.png;
    ".local/share/fastfetch/logos/logo-02.png".source = ./assets/fastfetch-logos/logo-02.png;
    ".local/share/fastfetch/logos/logo-03.webp".source = ./assets/fastfetch-logos/logo-03.webp;
  };
}

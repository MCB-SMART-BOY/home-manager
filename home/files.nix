{ ... }:

let
  portableFishFunctions = [
    "_mcb_toolchain"
    "backup"
    "bootstrap-toolchain"
    "check-toolchain"
    "copy"
    "extract"
    "fcd"
    "fe"
    "history"
    "mkcd"
    "upgrade-toolchain"
  ];

  fishFunctionFiles = builtins.listToAttrs (
    map (name: {
      name = "fish/functions/${name}.fish";
      value.source = ./config/fish/functions + "/${name}.fish";
    }) portableFishFunctions
  );

  fishConfDFiles = builtins.listToAttrs (
    map (name: {
      name = "fish/conf.d/${name}";
      value.source = ./config/fish/conf.d + "/${name}";
    }) (builtins.attrNames (builtins.readDir ./config/fish/conf.d))
  );
in
{
  xdg.configFile =
    fishFunctionFiles
    // fishConfDFiles
    // {
      "toolchain/tools.json".source = ./config/toolchain/tools.json;
      "starship.toml".source = ./config/starship/starship.toml;
      "btop/btop.conf".source = ./config/btop/btop.conf;
      "btop/themes/noctalia.theme".source = ./config/btop/themes/noctalia.theme;
      "fastfetch/config.jsonc".source = ./config/fastfetch/mokka.jsonc;
      "kitty/kitty.conf".source = ./config/kitty/kitty.conf;
      "helix/config.toml".source = ./config/helix/config.toml;
      "helix/languages.toml".source = ./config/helix/languages.toml;
      "clangd/config.yaml".source = ./config/clangd/config.yaml;
    };

  programs.tmux.extraConfig = builtins.readFile ./config/tmux/tmux.conf;

  home.file = {
    ".local/share/fastfetch/logos/logo-01.png".source = ./assets/fastfetch-logos/logo-01.png;
    ".local/share/fastfetch/logos/logo-02.png".source = ./assets/fastfetch-logos/logo-02.png;
    ".local/share/fastfetch/logos/logo-03.webp".source = ./assets/fastfetch-logos/logo-03.webp;
  };
}

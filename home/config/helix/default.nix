{ ... }:

{
  programs.helix.enable = true;

  xdg.configFile = {
    "helix/config.toml".source = ./config.toml;
    "helix/languages.toml".source = ./languages.toml;
  };
}

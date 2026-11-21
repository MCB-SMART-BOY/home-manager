{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = builtins.fromTOML (builtins.readFile ./config.toml);
    languages = builtins.fromTOML (builtins.readFile ./languages.toml);
    themes = {
      nord-night = ./themes/nord-night.toml;
      omarchy = ./themes/omarchy.toml;
    };
  };
}

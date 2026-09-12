{ ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}

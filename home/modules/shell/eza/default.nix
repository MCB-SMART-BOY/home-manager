_:

{
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = false;
    enableZshIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--time-style=long-iso"
    ];
    git = true;
  };

  home.shellAliases.tree = "eza --tree --icons --group-directories-first --git";
}

_:

{
  programs.zoxide = {
    enable = true;
    enableNushellIntegration = false;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  home.shellAliases = {
    j = "z";
    ji = "zi";
  };
}

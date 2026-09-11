{ ... }:

{
  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  home.shellAliases = {
    j = "z";
    ji = "zi";
  };
}

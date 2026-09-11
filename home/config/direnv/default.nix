{ ... }:

{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}

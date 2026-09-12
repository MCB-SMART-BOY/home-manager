{ pkgs, ... }:

{
  programs = {
    zellij.enable = true;
    jujutsu.enable = true;
  };

  home.packages = with pkgs; [ herdr ];
}

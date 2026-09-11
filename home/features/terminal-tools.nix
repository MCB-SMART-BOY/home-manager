{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zellij
    herdr
    jujutsu
  ];
}

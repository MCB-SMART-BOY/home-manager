{ pkgs, ... }:

{
  imports = [ ../config/mpv ];

  programs = {
    ncmpcpp.enable = true;
    ncspot.enable = true;
    obs-studio.enable = true;
  };

  home.packages = with pkgs; [
    mpd
    playerctl
  ];
}

{ pkgs, ... }:

{
  imports = [ ../config/mpv ];

  home.packages = with pkgs; [
    mpd
    ncmpcpp
    ncspot
    playerctl
    obs-studio
  ];
}

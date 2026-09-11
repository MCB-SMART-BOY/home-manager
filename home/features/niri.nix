{ pkgs, ... }:

# Niri binds launch these desktop commands directly. They are listed here so
# the public niri feature remains self-contained instead of relying on another
# optional feature's package set.
{
  imports = [
    ../desktop.nix
    ../config/niri
    ../config/noctalia
    ../config/fcitx5
    ../config/kitty
  ];

  home.packages = with pkgs; [
    nautilus
    google-chrome
    telegram-desktop
    obs-studio
    pavucontrol
    keepassxc
    mission-center
    playerctl
    grim
    slurp
    wl-clipboard
    satty

    waybar
    walker
    anyrun
    swaynotificationcenter
    swaylock-effects
    swaybg
    cliphist
    wf-recorder
    wlsunset
    rofi
  ];
}

{ pkgs, ... }:

# Niri binds launch these desktop commands directly. They are listed here so
# the public niri feature remains self-contained instead of relying on another
# optional feature's package set. Steam itself is intentionally supplied by
# the separate gaming feature or by the host; this feature retains only the
# launcher integration required by its Mod+G binding.
{
  imports = [
    ../desktop.nix
    ../config/niri
    ../config/noctalia
    ../config/fcitx5
    ../config/kitty
    ../config/chrome
    ../config/waybar
  ];

  programs = {
    keepassxc.enable = true;
    obs-studio.enable = true;
  };

  home.packages = with pkgs; [
    nautilus
    telegram-desktop
    pavucontrol
    mission-center
    playerctl
    grim
    slurp
    wl-clipboard
    satty

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

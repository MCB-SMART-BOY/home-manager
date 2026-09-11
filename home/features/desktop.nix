{ pkgs, ... }:

{
  imports = [
    ../desktop.nix
    ../config/kitty
  ];

  home.packages = with pkgs; [
    telegram-desktop
    nautilus
    file-roller
    imv
    zathura
    papers
    kdePackages.kdenlive
    baobab
    mission-center
    localsend
    deja-dup
    keepassxc
    simple-scan
    qbittorrent
    aria2
    gparted
    pavucontrol
  ];
}

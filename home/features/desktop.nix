{ pkgs, ... }:

{
  imports = [ ../desktop.nix ];

  home.packages = with pkgs; [
    kitty
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

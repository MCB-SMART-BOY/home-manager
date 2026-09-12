{ pkgs, ... }:

{
  imports = [
    ../desktop.nix
    ../config/kitty
  ];

  programs = {
    aria2.enable = true;
    imv.enable = true;
    keepassxc.enable = true;
    zathura.enable = true;
  };

  home.packages = with pkgs; [
    telegram-desktop
    nautilus
    file-roller
    papers
    kdePackages.kdenlive
    baobab
    mission-center
    localsend
    deja-dup
    simple-scan
    qbittorrent
    gparted
    pavucontrol
  ];
}

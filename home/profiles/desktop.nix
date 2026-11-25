{
  pkgs,
  ...
}:

{
  imports = [
    ../modules/desktop
    ../modules/appearance
    ../modules/apps/chrome
  ];

  programs = {
    aria2.enable = true;
    imv.enable = true;
    keepassxc.enable = true;
    obs-studio.enable = true;
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

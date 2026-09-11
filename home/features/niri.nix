{ pkgs, ... }:

let
  niriRun = pkgs.writeShellApplication {
    name = "niri-run";
    text = ''
      exec "$@"
    '';
  };

  lockScreen = pkgs.writeShellApplication {
    name = "lock-screen";
    text = ''
      exec noctalia msg session lock
    '';
  };

  steamLauncher = pkgs.writeShellApplication {
    name = "steam-launcher";
    text = ''
      exec steam "$@"
    '';
  };
in
{
  imports = [
    ../desktop.nix
    ../noctalia.nix
  ];

  home.packages =
    (with pkgs; [
      niri
      noctalia
      swayidle
      steam
      kitty
      nautilus
      google-chrome
      telegram-desktop
      obs-studio
      pavucontrol
      keepassxc
      mission-center
      grim
      slurp
      wl-clipboard
      playerctl
      linux-wallpaperengine
      satty
    ])
    ++ [
      niriRun
      lockScreen
      steamLauncher
    ];

  home.file = {
    ".local/bin/niri-run".source = "${niriRun}/bin/niri-run";
    ".local/bin/lock-screen".source = "${lockScreen}/bin/lock-screen";
    ".local/bin/steam-launcher".source = "${steamLauncher}/bin/steam-launcher";
  };

  xdg.configFile = {
    "niri/config.kdl".source = ../config/niri/config.kdl;
    "niri/outputs.kdl".source = ../config/niri/outputs.kdl;
    "niri/rules.kdl".source = ../config/niri/rules.kdl;
    "niri/binds.kdl".source = ../config/niri/binds.kdl;
    "fcitx5/profile".source = ../config/fcitx5/profile;
    "fcitx5/conf/classicui.conf".source = ../config/fcitx5/conf/classicui.conf;
  };

  home.file."Pictures/Wallpapers" = {
    source = ../assets/wallpapers;
    recursive = true;
  };
}

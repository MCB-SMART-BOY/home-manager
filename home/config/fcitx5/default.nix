{ pkgs, ... }:

{
  home.packages = [
    pkgs.fcitx5
    pkgs.fcitx5-rime
    pkgs.fcitx5-gtk
    pkgs.qt6Packages.fcitx5-qt
  ];

  xdg.configFile = {
    "fcitx5/profile".source = ./profile;
    "fcitx5/conf/classicui.conf".source = ./conf/classicui.conf;
  };
}

{ pkgs, ... }:

{
  imports = [
    ../config/bilibili
    ../config/clash-nyanpasu
    ../config/clash-verge
    ../config/kazumi
    ../config/wemeet
  ];

  home.packages = with pkgs; [
    metacubexd
    ani-cli
    mangayomi
  ];
}

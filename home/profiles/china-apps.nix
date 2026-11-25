{
  pkgs,
  ...
}:

{
  imports = [
    ../modules/apps/bilibili
    ../modules/apps/clash-verge
    ../modules/apps/kazumi
    ../modules/apps/wemeet
  ];

  home.packages = with pkgs; [
    metacubexd
    ani-cli
    mangayomi
  ];
}

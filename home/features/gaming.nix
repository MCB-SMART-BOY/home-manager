{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wineWow64Packages.stable
    winetricks
  ];
}

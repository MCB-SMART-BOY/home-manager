{ pkgs, ... }:

{
  # Steam is owned by the gaming capability; Niri retains only its launcher integration.
  home.packages = with pkgs; [
    steam
    wineWow64Packages.stable
    winetricks
  ];
}

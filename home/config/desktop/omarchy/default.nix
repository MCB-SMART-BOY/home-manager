{ lib, pkgs, ... }:

{
  xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
    "omarchy/shell.toml".source = ./shell.toml;
    "hypr/hyprland.lua".source = ./hyprland.lua;
    "hypr/looknfeel.lua".source = ./looknfeel.lua;
  };
}

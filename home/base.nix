{ config, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  programs.home-manager.enable = true;

  xdg.enable = true;
  home.sessionVariables.MANPAGER = "less -R";

  home.sessionPath = [ "${homeDir}/.local/bin" ];
}

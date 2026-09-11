{ pkgs, ... }:

{
  home.packages = [ pkgs.clang-tools ];
  xdg.configFile."clangd/config.yaml".source = ./config.yaml;
}

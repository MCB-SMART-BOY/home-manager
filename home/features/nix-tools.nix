{ pkgs, ... }:

{
  programs = {
    nh.enable = true;
    nix-index.enable = true;
  };

  home.packages = with pkgs; [
    nix-output-monitor
    comma
    nix-tree
    nix-du
    nurl
  ];
}

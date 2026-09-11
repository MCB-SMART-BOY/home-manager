{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nix-output-monitor
    nix-index
    comma
    nh
    nix-tree
    nix-du
    nurl
  ];
}

{ pkgs, ... }:

{
  programs.distrobox.enable = true;

  home.packages = with pkgs; [
    winboat
    podman-compose
    firecracker
  ];
}

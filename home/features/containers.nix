{ pkgs, ... }:

{
  home.packages = with pkgs; [
    podman-compose
    distrobox
    firecracker
  ];
}

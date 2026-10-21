{ pkgs, ... }:

{
  programs.distrobox.enable = true;

  home.packages = with pkgs; [
    # Use upstream defaults; per-VM settings such as VMX stay in its saved Compose file.
    winboat
    podman-compose
    firecracker
    distrobox
  ];
}

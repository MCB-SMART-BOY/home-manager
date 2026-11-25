{
  pkgs,
  ...
}:

{
  programs.distrobox.enable = true;

  home.packages = with pkgs; [
    podman-compose
    distrobox
  ];
}

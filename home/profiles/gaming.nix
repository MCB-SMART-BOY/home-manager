{
  pkgs,
  ...
}:

{
  # Steam is x86_64-linux only and is intentionally not part of this profile.
  # Wine and Winetricks remain available on all supported Linux architectures.
  home.packages = [
    pkgs.wineWow64Packages.stable
    pkgs.winetricks
  ];
}

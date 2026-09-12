{ pkgs, ... }:

{
  # Kazumi is deliberately host-provided: install the Flatpak
  # io.github.Predidit.Kazumi separately; this module only registers its launcher.
  xdg.dataFile."applications/io.github.Predidit.Kazumi.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Kazumi
    Comment=Watch Animes online with danmaku support.
    Exec=${pkgs.coreutils}/bin/env PATH=/app/bin:/usr/bin ${pkgs.flatpak}/bin/flatpak run io.github.Predidit.Kazumi
    Icon=io.github.Predidit.Kazumi
    Terminal=false
    StartupNotify=false
    Categories=AudioVideo;
    X-Flatpak=io.github.Predidit.Kazumi
  '';
}

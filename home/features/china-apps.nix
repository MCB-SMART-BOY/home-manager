{ pkgs, ... }:

let
  wemeetXwaylandMesa = pkgs.writeShellApplication {
    name = "wemeet-xwayland-mesa";
    text = ''
      export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
      exec ${pkgs.wemeet}/bin/wemeet-xwayland "$@"
    '';
  };
in
{
  home.packages = with pkgs; [
    wemeet
    wemeetXwaylandMesa
    clash-nyanpasu
    metacubexd
    ani-cli
    bilibili
    mangayomi
  ];

  xdg.desktopEntries = {
    "io.github.msojocs.bilibili" = {
      name = "Bilibili";
      comment = "Bilibili Desktop";
      exec = "bilibili %U";
      icon = "io.github.msojocs.bilibili";
      categories = [
        "AudioVideo"
        "Video"
        "TV"
      ];
      settings.Keywords = "bilibili;b站;视频;动漫;";
      terminal = false;
    };
    "clash-nyanpasu" = {
      name = "Clash Nyanpasu";
      comment = "Clash Nyanpasu! (∠・ω< )⌒☆";
      exec = "clash-nyanpasu";
      icon = "clash-nyanpasu";
      categories = [ "Development" ];
      startupNotify = true;
      terminal = false;
    };
    "clash-verge" = {
      name = "Clash Verge";
      comment = "Clash Verge Rev";
      exec = "clash-verge %U";
      icon = "clash-verge";
      categories = [ "Development" ];
      mimeType = [ "x-scheme-handler/clash" ];
      startupNotify = true;
      terminal = false;
    };
  };

  xdg.dataFile."applications/wemeetapp.desktop".text = ''
    [Desktop Entry]
    Name=WemeetApp
    Name[zh_CN]=腾讯会议
    Exec=wemeet-xwayland-mesa %u
    Icon=wemeet
    Type=Application
    Terminal=false
    Categories=AudioVideo;
    MimeType=x-scheme-handler/wemeet;
  '';

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

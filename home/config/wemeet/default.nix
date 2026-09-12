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
  home.packages = [
    pkgs.wemeet
    wemeetXwaylandMesa
  ];

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
}

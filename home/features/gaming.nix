{ pkgs, ... }:

let
  # Steam bundles an older Fontconfig that cannot parse the host's current
  # /etc/fonts/conf.d rules. Keep its config self-contained and point it at
  # fonts mounted into the Steam FHS environment.
  steamFontConfig = pkgs.writeText "steam-fontconfig.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <cachedir>~/.cache/fontconfig</cachedir>
      <dir>/usr/share/fonts</dir>
      <dir>${pkgs.noto-fonts-cjk-sans}</dir>
    </fontconfig>
  '';

  steam = pkgs.steam.override (prev: {
    extraPkgs =
      pkgs:
      (if prev ? extraPkgs then prev.extraPkgs pkgs else [ ])
      ++ [ pkgs.noto-fonts-cjk-sans ];
    extraEnv = (prev.extraEnv or { }) // {
      FONTCONFIG_FILE = "${steamFontConfig}";
    };
  });
in
{
  home.packages = [
    steam
    pkgs.wineWow64Packages.stable
    pkgs.winetricks
  ];
}

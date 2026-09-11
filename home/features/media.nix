{ pkgs, ... }:

let
  secureUosc = pkgs.mpvScripts.uosc.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + builtins.readFile ../scripts/secure-uosc-post-patch.sh;
  });
in
{
  imports = [ ../mpv.nix ];

  home.packages = with pkgs; [
    mpd
    ncmpcpp
    ncspot
    playerctl
    obs-studio
  ];

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      secureUosc
      thumbfast
      autoload
      mpris
    ];
    scriptOpts = {
      thumbfast = {
        max_width = 320;
        max_height = 180;
        tone_mapping = "auto";
      };
      autoload = {
        images = false;
        same_type = true;
        ignore_hidden = true;
      };
    };
  };
}

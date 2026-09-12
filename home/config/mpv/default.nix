{ pkgs, ... }:
let
  holdForwardSource = pkgs.writeText "hold_forward.lua" (builtins.readFile ./hold_forward.lua);
  holdForwardScript =
    pkgs.runCommand "mpv-hold-forward"
      {
        passthru = {
          scriptName = "hold_forward.lua";
        };
      }
      ''
        install -Dm644 ${holdForwardSource} "$out/share/mpv/scripts/hold_forward.lua"
      '';
  secureUosc = pkgs.mpvScripts.uosc.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + builtins.readFile ./patches/secure-uosc-post-patch.sh;
  });
in
{
  programs.mpv = {
    enable = true;

    config = {
      vo = "gpu-next";
      profile = "high-quality";
      hwdec = "auto";
      "video-sync" = "display-resample";
      "osd-bar" = false;
      border = false;
      "audio-file-auto" = "exact";
      "sub-auto" = "fuzzy";
      embeddedfonts = true;
      "blend-subtitles" = true;
      fs = true;
      "x11-bypass-compositor" = false;
      "volume-max" = 250;
      "save-position-on-quit" = true;
      "input-ar-delay" = 300;
      "input-ar-rate" = 6;
    };

    scripts = with pkgs.mpvScripts; [
      holdForwardScript
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

    bindings = {
      SPACE = "cycle pause";
      LEFT = "repeatable seek -5";
      RIGHT = "script-binding hold_forward/forward";
      UP = "repeatable add volume 5";
      DOWN = "repeatable add volume -5";
      h = "repeatable seek -5";
      l = "script-binding hold_forward/forward";
      j = "repeatable add volume -2";
      k = "repeatable add volume 2";
      f = "cycle fullscreen";
      m = "cycle mute";
    };

    extraInput = ''
      mbtn_right script-binding uosc/menu #! Menu
      tab script-binding uosc/toggle-ui #! Toggle UI
      ctrl+o script-binding uosc/open-file #! Open file
      ctrl+p script-binding uosc/items #! Playlist
      alt+i script-binding uosc/keybinds #! Key bindings
      ctrl+s async screenshot #! Screenshot
    '';
  };
}

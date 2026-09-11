# 用户 MPV 偏好；共享软件与脚本由 home/features/media.nix 提供。

{ pkgs, ... }:
let
  holdForwardSource = pkgs.writeText "hold_forward.lua" ''
    local HOLD_SPEED = 3.0
    local SEEK_SECONDS = 5
    local msg = require("mp.msg")

    local state = {
      is_down = false,
      is_long = false,
      saved_speed = nil,
    }

    local function reset_state()
      state.is_down = false
      state.is_long = false
      state.saved_speed = nil
    end

    local function restore_speed()
      if state.saved_speed ~= nil then
        mp.set_property_number("speed", state.saved_speed)
      end
      reset_state()
    end

    local function seek_forward()
      mp.commandv("seek", SEEK_SECONDS, "relative")
    end

    local function handle_forward(event)
      if event.event == "down" then
        if state.is_down then
          restore_speed()
        end
        state.is_down = true
        return
      end

      if event.event == "repeat" then
        state.is_down = true
        if state.is_long then
          if mp.get_property_bool("pause") then
            seek_forward()
          end
          return
        end

        state.saved_speed = mp.get_property_number("speed")
        if state.saved_speed == nil then
          msg.error("hold_forward: unable to read current playback speed")
          reset_state()
          return
        end

        state.is_long = true
        if mp.get_property_bool("pause") then
          seek_forward()
        else
          mp.set_property_number("speed", HOLD_SPEED)
        end
        return
      end

      if event.event == "up" then
        if event.canceled then
          restore_speed()
        elseif state.is_long then
          restore_speed()
        else
          seek_forward()
          reset_state()
        end
        return
      end

      if event.event == "press" then
        seek_forward()
        reset_state()
      end
    end

    mp.add_key_binding(nil, "forward", handle_forward, { complex = true })
  '';
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
in

{
  programs.mpv = {
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

    scripts = [ holdForwardScript ];

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

{
  programs.kitty = {
    enable = true;
    settings = {
      hide_window_decorations = true;
      window_padding_width = 18;
      background_opacity = 0.90;
      dynamic_background_opacity = true;
      window_alert_on_bell = false;
      confirm_os_window_close = 0;
      initial_window_width = "110c";
      initial_window_height = "32c";
      scrollback_lines = 20000;
      scrollback_pager_history_size = 128;
      wheel_scroll_multiplier = 3.0;
      touch_scroll_multiplier = 3.0;
      font_family = "JetBrainsMono Nerd Font";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = 15.5;
      adjust_line_height = 0;
      adjust_column_width = 0;
      disable_ligatures = "never";
      cursor_shape = "block";
      cursor_blink_interval = 0.5;
      cursor_stop_blinking_after = 0.0;
      copy_on_select = true;
      strip_trailing_spaces = "smart";
      mouse_hide_wait = -1.0;
      click_interval = 0.5;
      focus_follows_mouse = false;
      enable_audio_bell = false;
      visual_bell_duration = 0.0;
      allow_remote_control = true;
      placement_strategy = "center";
      shell = "fish";
      window_title_format = "{title} — kitty";
    };
    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+n" = "new_window";
      "ctrl+equal" = "change_font_size all +1.0";
      "ctrl+plus" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";
      "ctrl+0" = "change_font_size all restore";
    };
    extraConfig = ''
      include ${./fallback.conf}
    '';
  };
}

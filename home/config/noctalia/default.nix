# Noctalia v5 user configuration.
# This module owns Noctalia's generated and validated user-level TOML.

{ pkgs, ... }:

let
  settings = {
    # ── 全局 Shell ──
    shell = {
      lang = "zh-Hans";
      settings_show_advanced = true;
      clipboard_history_max_entries = 200;
      polkit_agent = true; # Noctalia 直接提供 polkit agent

      panel = {
        transparency_mode = "soft"; # 配合 Catppuccin 主题的半透明面板
        launcher_placement = "floating"; # 浮动式启动器，不依附顶栏
      };
    };

    # ── 主题（Catppuccin Mocha Dark）──
    theme = {
      mode = "dark";
      source = "builtin";
      builtin = "Catppuccin";
    };

    # ── 壁纸背景模糊（Niri overview backdrop）──
    backdrop = {
      enabled = true;
      blur_intensity = 0.5;
      tint_intensity = 0.3;
    };

    # ── 壁纸自动轮换 ──
    wallpaper = {
      enabled = true;
      directory = "~/Pictures/Wallpapers";
      automation = {
        enabled = true;
        interval_seconds = 1800;
        order = "random";
        recursive = true;
      };
    };

    # ── 锁屏（配合 swayidle 与 lock-screen 脚本的 noctalia msg session lock）──
    lockscreen = {
      enabled = true;
      blurred_desktop = true; # 模糊桌面快照作为锁屏背景（需 wlr-screencopy，Niri 支持）
      blur_intensity = 0.5;
      tint_intensity = 0.3;
    };

    # ── 社区插件：Wallpaper Engine 控制器 ──
    plugins.enabled = [ "tadomika_ari/w-engine" ];
    plugin_settings."tadomika_ari/w-engine".sync_colors = true;

    # W Engine 控件负责打开插件面板；插件服务独占 linux-wallpaperengine 进程。
    widget."w-engine".type = "tadomika_ari/w-engine:w-engine-widget";

    # ── 顶栏（内置 + W Engine widget）──
    bar.main = {
      position = "top";
      start = [
        "launcher"
        "workspaces"
        "tray"
        "w-engine"
      ];
      center = [ "clock" ];
      end = [
        "media"
        "notifications"
        "network"
        "bluetooth"
        "volume"
        "brightness"
        "battery"
        "control-center"
      ];
    };
  };
in
{
  programs.noctalia = {
    enable = true;
    package = pkgs.noctalia;
    settings = settings;
  };

  home.packages = [ pkgs.linux-wallpaperengine ];

  home.file."Pictures/Wallpapers" = {
    source = ../../assets/wallpapers;
    recursive = true;
  };
}

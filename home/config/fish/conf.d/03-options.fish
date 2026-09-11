# ══════════════════════════════════════════════════════════════════
# Fish 行为选项与历史记录
# ══════════════════════════════════════════════════════════════════
# 来源: ~/.config/fish/conf.d/03-options.fish

# Fish 使用 fish_history 控制 session 名称；不要伪造不受支持的文件/容量开关。
if not status is-interactive
    return
end


# ── 自动补全与建议 ──
set -g fish_autosuggestion_enabled 1
set -g fish_complete_in_word       1

# ── 路径显示 ──
set -g fish_use_abbreviated_home  1   # 显示 ~ 而非 /home/user

# ── UI 行为 ──
set -g fish_audio_enabled  0         # 关蜂鸣
set -g fish_greeting       ""        # 手动控制欢迎语（见 config.fish）
set -g fish_cursor_default block     # 块状光标
set -g fish_cursor_insert  line      # 插入模式用细线光标
set -g fish_cursor_replace underscore
set -g fish_cursor_visual  block

# ── 性能优化 ──
set -g fish_escape_delay_ms   20     # 减少 Esc 等待时间（默认 30ms）
set -g fish_sequence_key_delay_ms 100  # 按键序列超时

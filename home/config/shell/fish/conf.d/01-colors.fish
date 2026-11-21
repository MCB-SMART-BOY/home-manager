# ══════════════════════════════════════════════════════════════════
# Fish Shell — Catppuccin Mocha 配色方案
# ══════════════════════════════════════════════════════════════════
# 来源: ~/.config/fish/conf.d/01-colors.fish
#
# 完整的 Catppuccin Mocha 调色板应用于 Fish 的每个 UI 元素。
# 配色优先保证可读性和对比度，适用于深色终端背景。

if not status is-interactive
    return
end

# ── 基础文字颜色 ──
set -g fish_color_normal              cdd6f4   # Text       — 正文
set -g fish_color_command             89b4fa   # Blue       — 命令名
set -g fish_color_keyword             cba6f7   # Mauve      — 关键字（if/for/while）
set -g fish_color_quote               a6e3a1   # Green      — 引号内字符串
set -g fish_color_redirection         f5c2e7   # Pink       — 重定向符号 > >> < |
set -g fish_color_end                 f38ba8   # Red        — 语句结束符 end/end)
set -g fish_color_error               f38ba8   # Red        — 语法错误
set -g fish_color_param               cdd6f4   # Text       — 普通参数
set -g fish_color_option              f9e2af   # Yellow     — 命令选项 (-x --xxx)
set -g fish_color_comment             6c7086   # Overlay0   — 注释
set -g fish_color_operator            89dceb   # Sky        — 运算符
set -g fish_color_escape              fab387   # Peach      — 转义字符 \n \t

# ── 搜索与选中 ──
set -g fish_color_selection           --background=313244   # Surface0 — 选中文本背景
set -g fish_color_search_match        --background=f9e2af   # Yellow   — 搜索高亮
set -g fish_color_cancel              f38ba8   # Red        — 已取消的命令

# ── 路径与特殊元素 ──
set -g fish_color_cwd                 89b4fa   # Blue       — 当前工作目录
set -g fish_color_cwd_root            f38ba8   # Red        — 以 root 运行时目录色
set -g fish_color_user                a6e3a1   # Green      — 用户名
set -g fish_color_host                89b4fa   # Blue       — 本机主机名
set -g fish_color_host_remote         fab387   # Peach      — SSH 远程主机名
set -g fish_color_statusline          cdd6f4   # Text       — 状态栏文字
set -g fish_color_valid_path          --underline             # 有效文件路径加下划线
set -g fish_color_match               cba6f7   # Mauve      — 匹配文本高亮

# ── 自动建议与补全分页器 ──
set -g fish_color_autosuggestion      585b70   # Surface2   — 灰色自动建议
set -g fish_color_history_current     cba6f7   # Mauve      — 当前历史项
set -g fish_pager_color_progress      6c7086   # Overlay0   — 分页进度
set -g fish_pager_color_prefix        cba6f7   # Mauve      — 补全公共前缀
set -g fish_pager_color_completion    cdd6f4   # Text       — 补全候选文字
set -g fish_pager_color_description   6c7086   # Overlay0   — 补全描述
set -g fish_pager_color_selected_background --background=45475a  # Surface1 — 选中项背景
set -g fish_pager_color_selected_prefix        cba6f7            # Mauve
set -g fish_pager_color_selected_completion    cdd6f4            # Text
set -g fish_pager_color_selected_description   a6adc8            # Subtext0
set -g fish_pager_color_secondary_background   --background=1e1e2e  # Base
set -g fish_pager_color_secondary_prefix       cba6f7
set -g fish_pager_color_secondary_completion   cdd6f4
set -g fish_pager_color_secondary_description  a6adc8

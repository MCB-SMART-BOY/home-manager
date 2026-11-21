# ══════════════════════════════════════════════════════════════════
# Fish Shell — 主配置文件
# ══════════════════════════════════════════════════════════════════
# ~/.config/fish/config.fish
# 平台：Home Manager portable core；Linux/NixOS 扩展由调用方显式接入
#
# 加载顺序:
#   1. conf.d/01-colors.fish     — Catppuccin Mocha 配色
#   2. conf.d/02-env.fish        — 环境变量 fallback
#   3. conf.d/03-options.fish    — Fish 行为选项与历史
#   4. conf.d/05-fzf.fish        — 模糊搜索集成
#   5. conf.d/08-bang-bang.fish  — 交互式历史绑定
#   6. config.fish               — 本文件（欢迎语）
#
# 函数: 置于 functions/ 目录，Fish 自动加载。

if status is-interactive
    # ── 🎉 欢迎语 ──
    # dumb 终端（如 Emacs shell / eshell）跳过，防止卡死。
    if test "$TERM" != dumb
        if type -q fastfetch
            fastfetch
        end
    end
end


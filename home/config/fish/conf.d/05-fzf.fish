# ══════════════════════════════════════════════════════════════════
# Fzf — 模糊搜索集成
# ══════════════════════════════════════════════════════════════════
# 来源: ~/.config/fish/conf.d/05-fzf.fish

if not status is-interactive
    return
end
if not type -q fzf
    return
end

# ── 基础配置 ──
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_DEFAULT_OPTS "
    --height 40%
    --layout=reverse
    --border=rounded
    --preview-window=right:60%
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"
set -gx FZF_CTRL_T_COMMAND  "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND   'fd --type d --hidden --follow --exclude .git'

# ── Fish 原生键绑定（fzf >= 0.48） ──
if type -q fzf_configure_bindings
    fzf_configure_bindings \
        --directory=\cf \
        --git_log=\cg \
        --history=\cr \
        --variables=\cv
end

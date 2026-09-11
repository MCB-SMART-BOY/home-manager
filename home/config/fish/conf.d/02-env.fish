# ══════════════════════════════════════════════════════════════════
# 环境变量 fallback
# ══════════════════════════════════════════════════════════════════
# Home Manager 的 home/base.nix 是托管会话的唯一环境来源。
# 这里仅为脱离 Home Manager 会话时的 Fish 启动提供缺失值 fallback。

# ── 默认编辑器 ──
if not set -q EDITOR
    if type -q hx
        set -gx EDITOR hx
    else
        set -gx EDITOR nvim
    end
end
if not set -q VISUAL
    set -gx VISUAL "$EDITOR"
end
if not set -q BROWSER
    set -gx BROWSER firefox
end

# ── man 手册使用 bat ──
if not set -q MANPAGER
    if type -q bat
        set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    else
        set -gx MANPAGER "less -R"
    end
end

# ── XDG 标准目录 ──
if not set -q XDG_CONFIG_HOME
    set -gx XDG_CONFIG_HOME "$HOME/.config"
end
if not set -q XDG_DATA_HOME
    set -gx XDG_DATA_HOME "$HOME/.local/share"
end
if not set -q XDG_CACHE_HOME
    set -gx XDG_CACHE_HOME "$HOME/.cache"
end
if not set -q XDG_STATE_HOME
    set -gx XDG_STATE_HOME "$HOME/.local/state"
end

# ── 开发环境 ──
if not set -q RUSTUP_HOME
    set -gx RUSTUP_HOME "$HOME/.rustup"
end
if not set -q CARGO_HOME
    set -gx CARGO_HOME "$HOME/.cargo"
end
if not set -q GOPATH
    set -gx GOPATH "$HOME/go"
end
if not set -q OPAMROOT
    set -gx OPAMROOT "$HOME/.opam"
end
if not set -q ELAN_HOME
    set -gx ELAN_HOME "$HOME/.elan"
end
if not set -q BUN_INSTALL
    set -gx BUN_INSTALL "$HOME/.bun"
end
if not set -q UV_TOOL_BIN_DIR
    set -gx UV_TOOL_BIN_DIR "$HOME/.local/bin"
end

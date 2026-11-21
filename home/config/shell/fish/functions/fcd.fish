# fzf: 模糊搜索目录并进入
# 用法：fcd
function fcd
    set -l dir (fd --type d --hidden --exclude .git | fzf --preview 'eza -la --icons {}')
    if test -n "$dir"
        cd "$dir"
    end
end

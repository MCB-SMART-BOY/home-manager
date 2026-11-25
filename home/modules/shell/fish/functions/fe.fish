# fzf: 模糊搜索文件并用编辑器打开
# 用法：fe
function fe
    set -l preview_cmd
    if command -q bat
        set preview_cmd 'bat --color=always {}'
    else
        set preview_cmd 'sed -n "1,200p" {}'
    end

    set -l file (fd --type f --hidden --exclude .git | fzf --preview "$preview_cmd")
    if test -n "$file"
        $EDITOR "$file"
    end
end

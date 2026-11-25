# 万能解压函数 (自动识别格式)
# 用法：extract <压缩包>
function extract --argument-names archive
    if test (count $argv) -lt 1
        echo "用法: extract <archive>"
        return 1
    end

    if test -f "$archive"
        # 优先使用 ouch
        if command -q ouch
            ouch decompress "$archive"
            return $status
        end

        switch "$archive"
            case '*.tar.bz2'
                tar xjf "$archive"
            case '*.tar.gz'
                tar xzf "$archive"
            case '*.tar.xz'
                tar xJf "$archive"
            case '*.bz2'
                bunzip2 "$archive"
            case '*.gz'
                gunzip "$archive"
            case '*.tar'
                tar xf "$archive"
            case '*.tbz2'
                tar xjf "$archive"
            case '*.tgz'
                tar xzf "$archive"
            case '*.zip'
                unzip "$archive"
            case '*.Z'
                uncompress "$archive"
            case '*.7z'
                7z x "$archive"
            case '*.rar'
                unrar x "$archive"
            case '*'
                echo "'$archive' 无法识别的压缩格式"
        end
    else
        echo "'$archive' 不是有效文件"
    end
end

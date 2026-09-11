function _mcb_toolchain
    set -l executable "$HOME/.local/bin/mcb-toolchain"
    if not test -x "$executable"
        echo "mcb-toolchain 未找到；请重新构建 Home Manager 配置" >&2
        return 127
    end

    command "$executable" $argv
    return $status
end

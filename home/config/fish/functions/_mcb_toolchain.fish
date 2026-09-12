function _mcb_toolchain
    if not command -q mcb-toolchain
        echo "mcb-toolchain 未找到；请重新构建 Home Manager 配置" >&2
        return 127
    end

    command mcb-toolchain $argv
    return $status
end

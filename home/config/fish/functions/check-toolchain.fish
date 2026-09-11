# 检查各语言生态工具链是否可用。
# 用法：check-toolchain

function check-toolchain
    if test (count $argv) -gt 0
        echo "用法：check-toolchain"
        return 2
    end

    _mcb_toolchain check
end

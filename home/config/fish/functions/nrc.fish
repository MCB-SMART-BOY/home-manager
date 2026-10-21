# 快速查看将要构建/下载的 derivations（判断是否会源码编译）
# 用法：nrc [flake 引用]
function nrc --argument-names flake
    if test (count $argv) -eq 0
        _mcb_nixos_root check
    else
        @MCB_NIXOS_EXECUTABLE@ check $argv
    end
end

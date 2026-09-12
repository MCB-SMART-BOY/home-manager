# 快速查看将要构建/下载的 derivations（判断是否会源码编译）
# 用法：nrc [flake 引用]
function nrc --argument-names flake
    mcb-nixos check $argv
end

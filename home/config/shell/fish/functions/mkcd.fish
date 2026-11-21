# 创建目录并立即进入
# 用法：mkcd <目录名>
function mkcd
    mkdir -p $argv && cd $argv[-1]
end

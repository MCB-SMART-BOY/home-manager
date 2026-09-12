# 按当前 flake.lock 重建，不隐式升级依赖
# 用法：nrs [额外参数]
function nrs
    mcb-nixos switch $argv
end

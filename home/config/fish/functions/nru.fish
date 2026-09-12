# 更新 flake.lock 后重建
# 用法：nru [额外参数]
function nru
    mcb-nixos update-switch $argv
end

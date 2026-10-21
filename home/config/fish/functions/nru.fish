# 更新 flake.lock 后重建
# 用法：nru [额外参数]
function nru
    _mcb_nixos_root update-switch $argv
end

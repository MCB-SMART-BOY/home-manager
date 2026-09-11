# 更新 flake.lock 后重建
# 用法：nru [额外参数]
function nru
    _mcb_flake_target >/dev/null
    or return 1
    nfu
    and nrs $argv
end

# 按当前 flake.lock 重建，不隐式升级依赖
# 用法：nrs [额外参数]
function nrs
    set -l flake_ref (_mcb_flake_ref)
    or return 1
    /run/wrappers/bin/sudo nixos-rebuild switch --flake "$flake_ref" --show-trace $argv
end

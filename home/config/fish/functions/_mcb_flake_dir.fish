# 获取 flake 目录
# 用法：_mcb_flake_dir
function _mcb_flake_dir
    if set -q MCB_NIXOS_FLAKE_DIR; and test -n "$MCB_NIXOS_FLAKE_DIR"
        echo "$MCB_NIXOS_FLAKE_DIR"
    else
        echo "/etc/nixos"
    end
end

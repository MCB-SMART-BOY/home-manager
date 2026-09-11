# 获取 flake 引用
# 用法：_mcb_flake_ref
function _mcb_flake_ref
    set -l flake_source (_mcb_flake_source)
    or return 1
    set -l flake_target (_mcb_flake_target)
    or return 1
    printf '%s#%s\n' "$flake_source" "$flake_target"
end

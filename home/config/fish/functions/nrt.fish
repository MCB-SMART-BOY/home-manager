# 测试新配置但不设为默认
# 用法：nrt [额外参数]
function nrt
    set -l flake_ref (_mcb_flake_ref)
    or return 1
    /run/wrappers/bin/sudo nixos-rebuild test --flake "$flake_ref" --show-trace $argv
end

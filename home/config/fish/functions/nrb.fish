# 下次启动时应用
# 用法：nrb [额外参数]
function nrb
    set -l flake_ref (_mcb_flake_ref)
    or return 1
    /run/wrappers/bin/sudo nixos-rebuild boot --flake "$flake_ref" --show-trace $argv
end

# 显式更新 flake.lock
# 用法：nfu [额外参数]
function nfu
    /run/wrappers/bin/sudo nix flake update --flake "$(_mcb_flake_source)" $argv
end

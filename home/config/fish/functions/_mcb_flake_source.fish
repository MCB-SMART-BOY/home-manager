# 获取 flake source 引用
# 用法：_mcb_flake_source
function _mcb_flake_source
    set -l flake_dir (_mcb_flake_dir)
    if string match -q '*:*' -- "$flake_dir"
        echo "$flake_dir"
    else
        echo "path:$flake_dir"
    end
end

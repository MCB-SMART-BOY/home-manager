# 在 flake output 命名空间中解析当前 NixOS 目标
# 用法：_mcb_flake_target
function _mcb_flake_target
    if set -q MCB_NIXOS_FLAKE_TARGET; and test -n "$MCB_NIXOS_FLAKE_TARGET"
        echo "$MCB_NIXOS_FLAKE_TARGET"
        return 0
    end

    set -l flake_dir (_mcb_flake_dir)
    set -l local_dir
    if string match -q 'path:*' -- "$flake_dir"
        set local_dir (string replace -r '^path:' '' -- "$flake_dir")
    else if string match -q '*:*' -- "$flake_dir"
        printf 'Cannot infer a NixOS target from non-local flake source %s; set MCB_NIXOS_FLAKE_TARGET.\n' "$flake_dir" >&2
        return 1
    else
        set local_dir "$flake_dir"
    end

    set -l host_name
    if test -r /etc/hostname
        read -l host_name < /etc/hostname
    end
    if test -n "$host_name"; and test -f "$local_dir/machines/$host_name/default.nix"
        echo "$host_name"
        return 0
    end

    set -l candidates
    for default_nix in "$local_dir"/machines/*/default.nix
        test -f "$default_nix"; or continue
        set -l machine (path basename (path dirname "$default_nix"))
        switch "$machine"
            case _template ci
                continue
        end
        set -a candidates "$machine"
    end

    if test (count $candidates) -eq 1
        echo "$candidates[1]"
        return 0
    end

    printf 'Cannot determine a unique NixOS flake target in %s; set MCB_NIXOS_FLAKE_TARGET.\n' "$local_dir" >&2
    return 1
end

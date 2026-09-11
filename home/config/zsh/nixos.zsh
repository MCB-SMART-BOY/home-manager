# NixOS-specific helpers. Loaded only by home.nixos.

# --- NixOS 管理 ---
_mcb_flake_dir() {
    printf '%s\n' "${MCB_NIXOS_FLAKE_DIR:-/etc/nixos}"
}

_mcb_flake_source() {
    local flake_dir="$(_mcb_flake_dir)"
    case "${flake_dir}" in
        *:*) printf '%s\n' "${flake_dir}" ;;
        *) printf 'path:%s\n' "${flake_dir}" ;;
    esac
}

_mcb_flake_target() {
    if [[ -n "${MCB_NIXOS_FLAKE_TARGET:-}" ]]; then
        printf '%s\n' "${MCB_NIXOS_FLAKE_TARGET}"
        return 0
    fi

    local flake_dir local_dir hostname default_nix machine
    flake_dir="$(_mcb_flake_dir)" || return 1
    case "${flake_dir}" in
        path:*) local_dir="${flake_dir#path:}" ;;
        *:*)
            printf 'Cannot infer a NixOS target from non-local flake source %s; set MCB_NIXOS_FLAKE_TARGET.\n' "${flake_dir}" >&2
            return 1
            ;;
        *) local_dir="${flake_dir}" ;;
    esac

    hostname=""
    if [[ -r /etc/hostname ]]; then
        IFS= read -r hostname < /etc/hostname
    fi
    if [[ -n "${hostname}" && -f "${local_dir}/machines/${hostname}/default.nix" ]]; then
        printf '%s\n' "${hostname}"
        return 0
    fi

    local -a candidates=()
    setopt local_options null_glob
    for default_nix in "${local_dir}"/machines/*/default.nix; do
        [[ -f "${default_nix}" ]] || continue
        machine="${default_nix%/default.nix}"
        machine="${machine##*/}"
        case "${machine}" in
            _template|ci) continue ;;
        esac
        candidates+=("${machine}")
    done

    if [[ "${#candidates[@]}" -eq 1 ]]; then
        printf '%s\n' "${candidates[1]}"
        return 0
    fi

    printf 'Cannot determine a unique NixOS flake target in %s; set MCB_NIXOS_FLAKE_TARGET.\n' "${local_dir}" >&2
    return 1
}

_mcb_flake_ref() {
    local flake_source flake_target
    flake_source="$(_mcb_flake_source)" || return 1
    flake_target="$(_mcb_flake_target)" || return 1
    printf '%s#%s\n' "${flake_source}" "${flake_target}"
}

# 按当前 flake.lock 重建，不隐式升级依赖
nrs() {
    local flake_ref
    flake_ref="$(_mcb_flake_ref)" || return 1
    /run/wrappers/bin/sudo nixos-rebuild switch --flake "${flake_ref}" --show-trace "$@"
}

# 测试新配置但不设为默认
nrt() {
    local flake_ref
    flake_ref="$(_mcb_flake_ref)" || return 1
    /run/wrappers/bin/sudo nixos-rebuild test --flake "${flake_ref}" --show-trace "$@"
}

# 下次启动时应用
nrb() {
    local flake_ref
    flake_ref="$(_mcb_flake_ref)" || return 1
    /run/wrappers/bin/sudo nixos-rebuild boot --flake "${flake_ref}" --show-trace "$@"
}

# 显式更新 flake.lock
nfu() {
    /run/wrappers/bin/sudo nix flake update --flake "$(_mcb_flake_source)" "$@"
}

# 更新 flake.lock 后重建
nru() {
    _mcb_flake_target >/dev/null || return 1
    nfu && nrs "$@"
}


# 快速查看将要构建/下载的 derivations
nrc() {
    local flake="${1:-}"
    if [[ -z "${flake}" ]]; then
        local flake_source flake_target
        flake_source="$(_mcb_flake_source)" || return 1
        flake_target="$(_mcb_flake_target)" || return 1
        flake="${flake_source}#nixosConfigurations.${flake_target}.config.system.build.toplevel"
    fi
    nix build "${flake}" --dry-run
}

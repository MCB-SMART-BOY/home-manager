# NixOS-specific helpers. Loaded by the explicit home.platform.nixos entry point.

def please [...args: string] {
    ^/run/wrappers/bin/sudo ...$args
}

def ngc [] {
    ^/run/wrappers/bin/sudo nix-collect-garbage -d
}

# 仅传递明确的源和目标覆盖，避免把 PATH/NIX_CONFIG 带入 root 命令。
def --wrapped _mcb_nixos_root [...args: string] {
    let source = $env.MCB_NIXOS_FLAKE_DIR? | default ""
    let target = $env.MCB_NIXOS_FLAKE_TARGET? | default ""
    let host = $env.NIXD_HOST? | default ""
    ^@MCB_NIXOS_ENV@ -i $"MCB_NIXOS_FLAKE_DIR=($source)" $"MCB_NIXOS_FLAKE_TARGET=($target)" $"NIXD_HOST=($host)" /run/wrappers/bin/sudo --preserve-env=MCB_NIXOS_FLAKE_DIR,MCB_NIXOS_FLAKE_TARGET,NIXD_HOST -- @MCB_NIXOS_EXECUTABLE@ ...$args
}

def --wrapped nrs [...args: string] {
    _mcb_nixos_root switch ...$args
}

def --wrapped nrt [...args: string] {
    _mcb_nixos_root test ...$args
}

def --wrapped nrb [...args: string] {
    _mcb_nixos_root boot ...$args
}

def --wrapped nfu [...args: string] {
    _mcb_nixos_root update ...$args
}

def --wrapped nru [...args: string] {
    _mcb_nixos_root update-switch ...$args
}

def nrc [...args: string] {
    if ($args | is-empty) {
        _mcb_nixos_root check
    } else {
        ^@MCB_NIXOS_EXECUTABLE@ check ...$args
    }
}

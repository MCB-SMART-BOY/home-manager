# NixOS-specific helpers. Loaded only by home.nixos.

def please [...args: string] {
    ^/run/wrappers/bin/sudo ...$args
}

def ngc [] {
    ^/run/wrappers/bin/sudo nix-collect-garbage -d
}

def _flake_dir [] {
    $env.MCB_NIXOS_FLAKE_DIR? | default "/etc/nixos"
}

def _flake_source [] {
    let flake_dir = (_flake_dir)
    if ($flake_dir | str contains ":") {
        $flake_dir
    } else {
        $"path:($flake_dir)"
    }
}

def _flake_target [] {
    let explicit = ($env.MCB_NIXOS_FLAKE_TARGET? | default "")
    if ($explicit | is-not-empty) {
        return $explicit
    }

    let flake_dir = (_flake_dir)
    let local_dir = if ($flake_dir | str starts-with "path:") {
        $flake_dir | str replace --regex '^path:' ''
    } else if ($flake_dir | str contains ":") {
        error make { msg: $"Cannot infer a NixOS target from non-local flake source ($flake_dir); set MCB_NIXOS_FLAKE_TARGET." }
    } else {
        $flake_dir
    }

    let host = if ("/etc/hostname" | path exists) {
        open /etc/hostname | str trim
    } else {
        ""
    }
    if ($host | is-not-empty) and (($local_dir | path join "machines" $host "default.nix") | path exists) {
        return $host
    }

    let candidates = (
        glob ($local_dir | path join "machines" "*" "default.nix")
        | each {|item|
            let machine = ($item | path dirname | path basename)
            if $machine in ["_template", "ci"] { null } else { $machine }
        }
        | compact
    )
    if ($candidates | length) == 1 {
        return $candidates.0
    }
    error make { msg: $"Cannot determine a unique NixOS flake target in ($local_dir); set MCB_NIXOS_FLAKE_TARGET." }
}

def _flake_ref [] {
    $"(_flake_source)#(_flake_target)"
}

def nrs [...args: string] {
    ^/run/wrappers/bin/sudo nixos-rebuild switch --flake (_flake_ref) --show-trace ...$args
}

def nrt [...args: string] {
    ^/run/wrappers/bin/sudo nixos-rebuild test --flake (_flake_ref) --show-trace ...$args
}

def nrb [...args: string] {
    ^/run/wrappers/bin/sudo nixos-rebuild boot --flake (_flake_ref) --show-trace ...$args
}

def nfu [...args: string] {
    ^/run/wrappers/bin/sudo nix flake update --flake (_flake_source) ...$args
}

def nru [...args: string] {
    nfu
    if $env.LAST_EXIT_CODE == 0 {
        nrs ...$args
    }
}

def nrc [flake: string = ""] {
    let reference = if ($flake | is-empty) {
        $"(_flake_source)#nixosConfigurations.(_flake_target).config.system.build.toplevel"
    } else {
        $flake
    }
    ^nix build $reference --dry-run
}

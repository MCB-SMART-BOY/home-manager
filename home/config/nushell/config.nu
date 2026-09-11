# Nushell parity layer.
# Home Manager owns Starship, zoxide and direnv integration.
# Keep native ls/cp/mv/rm/cd commands structured; only add explicit helpers.

# ── Editor and filesystem helpers ─────────────────────────────────
def --env e [...args: string] {
    ^($env.EDITOR | default "hx") ...$args
}

def --env v [...args: string] {
    e ...$args
}

def --env mkcd [directory: path] {
    mkdir $directory
    cd $directory
}

def backup [filename: path] {
    if not ($filename | path exists) {
        error make { msg: $"file not found: ($filename)" }
    }
    ^cp -- $filename $"($filename).bak"
}

def copy [source: path, destination: path] {
    if not ($source | path exists) {
        error make { msg: $"source not found: ($source)" }
    }
    if (($source | path type) == "dir") {
        ^cp --recursive -- $source $destination
    } else {
        ^cp -- $source $destination
    }
}

def extract [archive: path] {
    if not ($archive | path exists) {
        error make { msg: $"archive not found: ($archive)" }
    }
    ^ouch decompress $archive
}

def fcd [] {
    if (which fd | is-empty) or (which fzf | is-empty) {
        error make { msg: "fcd requires fd and fzf" }
    }
    let selected = (^fd --type d --hidden --exclude .git | ^fzf --preview 'eza -la --icons {}' | str trim)
    if ($selected | is-not-empty) {
        cd $selected
    }
}

def fe [...args: string] {
    if (which fd | is-empty) or (which fzf | is-empty) {
        error make { msg: "fe requires fd and fzf" }
    }
    let selected = (^fd --type f --hidden --exclude .git | ^fzf --preview 'bat --color=always {}' | str trim)
    if ($selected | is-not-empty) {
        e $selected ...$args
    }
}

def .. [] { cd .. }
def ... [] { cd ../.. }
def .... [] { cd ../../.. }
def ..... [] { cd ../../../.. }
def up [] { cd .. }


# ── Toolchain wrappers ───────────────────────────────────────────
def _run-toolchain [operation: string, dry_run: bool] {
    let executable = ($env.HOME | path join ".local" "bin" "mcb-toolchain")
    if not ($executable | path exists) {
        error make { msg: $"mcb-toolchain not found: ($executable); rebuild Home Manager first" }
    }
    let args = if $dry_run { ["--dry-run"] } else { [] }
    let result = (run-external $executable $operation ...$args | complete)
    if ($result.stdout | is-not-empty) {
        print -n $result.stdout
    }
    if $result.exit_code != 0 {
        if ($result.stderr | is-not-empty) {
            print -e $result.stderr
        }
        error make { msg: $"mcb-toolchain ($operation) failed with exit code ($result.exit_code)" }
    }
    null
}

def bootstrap-toolchain [--dry-run] {
    _run-toolchain "bootstrap" $dry_run
}

def upgrade-toolchain [--dry-run] {
    _run-toolchain "upgrade" $dry_run
}

def check-toolchain [] {
    _run-toolchain "check" false
}

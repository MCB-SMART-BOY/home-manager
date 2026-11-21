# Nushell helpers and editor defaults.
# Keep native ls/cp/mv/rm/cd commands structured; only add explicit helpers.

$env.EDITOR = "hx"
$env.VISUAL = "hx"

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
        ^cp -R -- $source $destination
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

def --env fcd [] {
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

def --env up [] { cd .. }

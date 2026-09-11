# Nushell environment fallback.
# Home Manager home/base.nix owns the shared session variables and PATH.
if (($env.EDITOR? | default "") | is-empty) {
    $env.EDITOR = "hx"
}

# Repository context

- `flake.nix` is the thin entry point; `flake/default.nix` owns outputs and Home Manager construction.
- `home/default.nix` is the portable always-on module. It must not import NixOS, Niri, desktop, development, media, gaming, or other optional behavior.
- `home/config/**` and `home/assets/**` are source assets. Alias and shell-integration blocks are the approved exception for this refactor and may be removed when replaced by Home Manager declarations.
- `allowUnfree` is intentionally always enabled for this repository. Optional features contain `vscode-fhs`, `obsidian`, `wemeet`, `bilibili`, and `burpsuite`.
- Prefer Home Manager options over shell startup code. Keep raw shell files only for shell-specific functions, bindings, completion, and behavior with no native option.
- Runtime shell programs over three lines belong in `home/scripts/`, not multiline `text = ''` bodies in Nix.
- Do not create new repository guidance under `docs/`. Use `.agent/` for durable decisions and verification workflow.

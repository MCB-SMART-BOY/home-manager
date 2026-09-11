# Task 7 Report — Remove catch-all modules, orphan data, and stale ownership comments

## Status

PASS. The empty catch-all module and superseded root Git owner were removed after a repository reference inventory. Git now has one owner at `home/config/git/default.nix`; active raw configuration remains beside its owning module; proven orphan raw files were removed; and host-specific Niri outputs remain an explicit opt-in override.

The pre-existing unstaged correction to `task-3-report.md` was not modified or included.

## Reference inventory and decisions

Inventory scope was `home/` and `flake/`, covering Nix modules and raw configuration files. A raw file was treated as active only when an import, `source`, `builtins.readFile`, or generated deployment path referenced it.

| Candidate | Inventory result | Decision |
| --- | --- | --- |
| `home/git.nix` | Contained the only active `programs.git` declaration. `home/default.nix` also imported `home/config/git`; that owner was an empty placeholder. | Moved the declaration into `home/config/git/default.nix`, removed the root import, then deleted the root module. |
| `home/files.nix` | Empty after Tasks 2–6 migrated its mappings. | Removed the import and deleted the module. |
| `home/programs.nix`, `home/shell.nix`, `home/mpv.nix`, `home/noctalia.nix`, `home/nixvim/` | Absent after earlier migrations; no active imports or deployment references remain. | No additional deletion was needed in Task 7. |
| `home/config/alacritty/alacritty.toml` | Only the raw file and its self-description matched; no import, `source`, `readFile`, or generated deployment path referenced it. | Classified as orphan and removed. |
| `home/config/fuzzel/fuzzel.ini` | Only the raw file and its self-description matched; no active owner or deployment path referenced it. | Classified as orphan and removed. |
| `home/config/mako/config` | Only the raw file and its self-description matched; no active owner or deployment path referenced it. | Classified as orphan and removed. |
| `home/config/swaylock/config` | Only the raw file and its self-description matched; the Niri feature installs `swaylock-effects` but does not deploy this file. | Classified as orphan and removed. |
| `home/config/starship/mokka.toml` | `home/config/starship/default.nix` reads `./starship.toml`; no module reads `mokka.toml`. | Classified as an unused duplicate and removed. |
| GTK raw files/directories (`gtk-2.0`, `gtk-3.0`, `gtk-4.0`) | No active raw GTK deployment remains; Home Manager `gtk` options are the active owner. The raw files had already been removed by Task 5. | Confirmed absent/unreferenced; no duplicate deletion in this task. |
| `home/config/niri/outputs.kdl` | Explicitly referenced by `home/config/niri/default.nix` only when `mcb.niri.hostOutputs.enable` is true; `config.kdl` includes it optionally. | Retained as the documented host-specific opt-in output override. |
| Fastfetch logos under `home/config/fastfetch/assets/fastfetch-logos/` | `home/config/fastfetch/default.nix` maps all three logos into `.local/share/fastfetch/logos/`. | Retained beside the Fastfetch owner. |
| MPV assets and patch under `home/config/mpv/` | `home/config/mpv/default.nix` reads `hold_forward.lua` and `patches/secure-uosc-post-patch.sh`. | Retained beside the MPV owner. |
| Nixvim patch under `home/config/nixvim/patches/` | `home/config/nixvim/plugins.nix` reads `markdown-preview-bun-post-patch.sh`. | Retained beside the Nixvim owner. |
| Fcitx5 profile | `home/config/fcitx5/default.nix` deploys `profile`; the ownership comment already names that module. | Retained and verified. |

## Changes

- `home/config/git/default.nix`
  - Moved the complete Git declaration from `home/git.nix`.
- `home/default.nix`
  - Removed imports for deleted `./git.nix` and `./files.nix`; the existing `./config/git` import is now the sole Git owner.
- Deleted `home/git.nix` and `home/files.nix`.
- Deleted proven orphan/duplicate raw files:
  - `home/config/alacritty/alacritty.toml`
  - `home/config/fuzzel/fuzzel.ini`
  - `home/config/mako/config`
  - `home/config/swaylock/config`
  - `home/config/starship/mokka.toml`
- `home/config/btop/btop.conf`
  - Replaced the stale `scripts.nix` ownership comment with the NixOS platform-wrapper owner path (`config/btop/nixos.nix`).
- `home/config/fastfetch/mokka.jsonc`
  - Replaced the stale `files.nix` deployment comment with `home/config/fastfetch/default.nix`.
- `home/config/niri/outputs.kdl` was intentionally not removed or renamed; it remains opt-in as required.

## Verification

No formatter, linter, project-wide build, or project-wide test suite was run.

### Focused Nix parse

Command:

```bash
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
```

Result: PASS (exit 0; all targeted Nix files parsed without an error).

### Legacy-reference search

Repository search over `home/` and `flake/` used the catch-all/root-module pattern, excluding the `programs.nixvim` option namespace:

```text
files.nix|programs.nix([^v[:alnum:]_]|$)|home/(mpv|git|noctalia)\.nix|home/nixvim
```

Result: no matches found.

A second repository search for removed raw paths (`alacritty`, `fuzzel`, `mako`, `swaylock`, `starship/mokka.toml`, and GTK raw paths) also returned no matches in `home/` or `flake/`.

A stale-comment search for `files.nix`, `scripts.nix`, old root software paths, and the old Nixvim path returned no matches.

### Ownership/composition evaluation

Command:

```bash
nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); c = f.lib.mkHomeConfiguration { system = builtins.currentSystem; username = "task7-probe"; homeDirectory = "/tmp/task7-probe"; }; in { gitEnabled = c.config.programs.git.enable; gitLfs = c.config.programs.git.lfs.enable; gitEditor = c.config.programs.git.settings.core.editor; legacyGit = builtins.pathExists ./home/git.nix; catchAll = builtins.pathExists ./home/files.nix; legacyPrograms = builtins.pathExists ./home/programs.nix; legacyMpv = builtins.pathExists ./home/mpv.nix; legacyNoctalia = builtins.pathExists ./home/noctalia.nix; legacyNixvim = builtins.pathExists ./home/nixvim; hostOutputs = builtins.pathExists ./home/config/niri/outputs.kdl; fastfetchLogos = builtins.pathExists ./home/config/fastfetch/assets/fastfetch-logos/logo-01.png; mpvPatch = builtins.pathExists ./home/config/mpv/patches/secure-uosc-post-patch.sh; nixvimPatch = builtins.pathExists ./home/config/nixvim/patches/markdown-preview-bun-post-patch.sh; }'
```

Result: PASS (exit 0):

```json
{"catchAll":false,"fastfetchLogos":true,"gitEditor":"hx","gitEnabled":true,"gitLfs":true,"hostOutputs":true,"legacyGit":false,"legacyMpv":false,"legacyNixvim":false,"legacyNoctalia":false,"legacyPrograms":false,"mpvPatch":true,"nixvimPatch":true}
```

### Whitespace check

Command:

```bash
git diff --check
```

Result: PASS (exit 0; no whitespace errors).

## Runtime limitations and concerns

- No Home Manager activation, NixOS rebuild, shell startup, compositor session, Fastfetch invocation, MPV runtime, or interactive desktop session was run. Verification covers parsing, module composition, source-path existence, and reference absence only.
- The Niri output file is intentionally not deployed by the portable Niri composition unless a host enables `mcb.niri.hostOutputs.enable`; automatic output detection remains the default.
- The orphan raw files were removed based on the absence of active source/deployment references in `home/` and `flake/`; historical planning and report documents may still mention older paths and are not runtime references.

## Commit

`refactor: remove catch-all ownership modules` (the final commit ID is returned with the Task 7 status; it is intentionally not embedded here because changing a commit's own ID would require another content change).

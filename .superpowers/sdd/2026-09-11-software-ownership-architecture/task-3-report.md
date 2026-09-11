# Task 3 Report — Consolidate MPV, editor, terminal, and desktop software

## Status

PASS. MPV, always-on software, optional Kitty/Clangd configuration, and the Nixvim markdown-preview patch are now colocated with their software owners. Legacy MPV/program ownership modules and migrated `home/files.nix` mappings were removed while the `home/files.nix` module itself remains for Task 7.

`9c99377` — `refactor: consolidate software ownership`


## Changed files

- `home/config/mpv/default.nix`
  - Consolidated the complete MPV configuration, enablement, script list, script options, secure-uosc override, and key bindings.
  - Reads `hold_forward.lua` and `patches/secure-uosc-post-patch.sh` from the MPV owner directory.
- `home/config/mpv/hold_forward.lua`
  - Moved the inline hold-forward implementation without changing its behavior.
- `home/config/mpv/patches/secure-uosc-post-patch.sh`
  - Moved the secure-uosc patch beside its MPV consumer.
- `home/features/media.nix`
  - Retained only the MPV owner import and MPD/Ncmpcpp/Ncspot/playerctl/OBS package composition.
- `home/config/btop/default.nix`
  - Added Btop enablement and Btop config/theme deployment.
- `home/config/fastfetch/default.nix`
  - Added Fastfetch enablement, config deployment, and logo deployment.
- `home/config/fastfetch/assets/fastfetch-logos/`
  - Moved Fastfetch logo assets under the Fastfetch owner.
- `home/config/helix/default.nix`
  - Added portable Helix enablement and config/language deployment; `nixos.toml` remains separate.
- `home/config/toolchain/default.nix`
  - Added the `toolchain/tools.json` deployment; `home/scripts/mcb-toolchain` remains unchanged.
- `home/config/kitty/default.nix`
  - Added Kitty config deployment and Kitty package ownership.
- `home/config/clangd/default.nix`
  - Added Clangd config deployment and the development package dependency.
- `home/features/desktop.nix`
  - Imports Kitty and no longer declares Kitty directly in its package list.
- `home/features/development.nix`
  - Imports Clangd and no longer declares `clang-tools` directly in its package list.
- `home/config/nixvim/patches/markdown-preview-bun-post-patch.sh`
  - Moved the markdown-preview patch beside its Nixvim consumer.
- `home/config/nixvim/plugins.nix`
  - Updated the patch read path only.
- `home/default.nix`
  - Removed the obsolete `./programs.nix` import.
- `home/files.nix`
  - Removed migrated Btop/Fastfetch/Helix/Kitty/Clangd/Toolchain mappings while retaining the module for Task 7.
- `home/mpv.nix`, `home/programs.nix`
  - Deleted after migration.

No Noctalia, Niri, or platform logic was modified.

## Verification

Required parse check:

```text
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
PASS (exit 0)
```

Required media evaluation:

```text
nix eval --impure --raw --expr '... f.homeModules.media ...'
/tmp/media-probe (exit 0)
```

Required Nixvim evaluation:

```text
nix eval --impure --raw --expr '... f.homeModules.nixvim ...'
/tmp/nixvim-probe (exit 0)
```

Additional focused checks:

- Moved MPV, Nixvim patch, and Fastfetch asset paths exist: PASS.
- Deleted legacy files and old script paths are absent: PASS.
- Active Nix/shell sources contain no references to `home/mpv.nix`, `home/programs.nix`, or the old patch paths: PASS.
- No formatter, linter, or project-wide test suite was run.

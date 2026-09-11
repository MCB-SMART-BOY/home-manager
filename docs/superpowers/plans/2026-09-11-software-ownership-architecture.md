# Software-Owned Home Configuration Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the Home Manager repository so each software owns its Nix declaration, raw configuration, assets, and software-specific build patches under `home/config/<software>/`, while `home/features/` only composes capabilities and `home/platform/` only applies platform overlays.

**Architecture:** Treat `home/config/<software>/default.nix` as the single owner for a software. Static files live beside that module; software without static files, such as Git, still has a module but no artificial raw config. Feature modules import software modules and add capability packages; platform modules import platform-specific software overlays. Remove generic catch-all deployment modules after every mapping has a new owner.

**Tech Stack:** Nix, Nixpkgs unstable, Home Manager, Nixvim, Fish, Zsh, Nushell, Niri, Noctalia, Bash build hooks.

**Spec:** `.agent/design.md`

## Global Constraints

- `home/config/<software>/` is the only owner of that software's `programs.*`, `xdg.configFile`, `home.file`, raw configuration, assets, and build patches; software-specific packages belong there, while package-only capability bundles may remain in `home/features/`.
- `home/features/` composes software and capabilities; it does not duplicate a software's `programs.*` declaration.
- `home/platform/` contains Linux/NixOS-specific overlays and must not redefine portable software defaults.
- `home/files.nix` and `home/programs.nix` are removed after all mappings have explicit owners.
- Keep `nixpkgs.config.allowUnfree = true` and preserve the public `homeModules` API unless a change is required by the new ownership boundary.
- Do not create empty raw-config directories for software configured entirely through Home Manager options.
- Do not deploy an orphan file merely because it exists; classify it as active, host-specific, obsolete, or intentionally unmanaged before removal.
- Preserve effective behavior unless the current behavior is broken by an undeclared dependency, an unreferenced file, or a platform leak documented in the task.
- Every migration task ends with a focused Nix evaluation or syntax check; the full flake check runs only after all migrations are complete.

---

## File Map

### Software modules and data

Create or move these software-owned modules:

- `home/config/git/default.nix` — Git Home Manager options; no raw `.gitconfig`.
- `home/config/fish/default.nix` — Fish declaration, `config.fish`, `conf.d`, and functions deployment.
- `home/config/zsh/default.nix` — Zsh declaration, `.zshrc`, and shell integration.
- `home/config/nushell/default.nix` — Nushell declaration, `config.nu`, and `env.nu`.
- `home/config/eza/default.nix`, `direnv/default.nix`, `zoxide/default.nix`, `starship/default.nix`, `bat/default.nix`, `tmux/default.nix` — one native Home Manager owner per tool.
- `home/config/mpv/default.nix`, `hold_forward.lua`, and `patches/secure-uosc-post-patch.sh` — all MPV settings, scripts, and MPV-only patching.
- `home/config/noctalia/default.nix` — generated and validated Noctalia configuration; Noctalia-only assets/settings.
- `home/config/btop/default.nix`, `fastfetch/default.nix`, `helix/default.nix`, `kitty/default.nix`, `clangd/default.nix`, and `toolchain/default.nix` — declarations and their existing raw files.
- `home/config/niri/default.nix` — Niri KDL files and Niri-only wrappers/integration.
- `home/config/fcitx5/default.nix` — input-method package/config and desktop-session integration.
- `home/config/nixvim/` — move the existing Nixvim module directory here; keep `patches/markdown-preview-bun-post-patch.sh` with the markdown-preview consumer.

### Composition and platform modules

- Modify `home/default.nix` to import only portable base modules and always-on software modules.
- Modify `home/features/media.nix`, `desktop.nix`, `development.nix`, `niri.nix`, `research.nix`, `china-apps.nix`, `theming.nix`, `gaming.nix`, and the remaining feature modules to compose software owners without duplicating their configuration.
- Create `home/platform/nixos.nix` as the platform composition boundary and move NixOS-specific overlays into software-owned `nixos.nix` files where they modify that software.
- Modify `flake/default.nix` to expose the moved `homeModules.nixvim` and `homeModules.nixos` paths.
- Remove `home/files.nix`, `home/programs.nix`, `home/shell.nix`, `home/mpv.nix`, `home/git.nix`, `home/noctalia.nix`, and the old `home/nixvim/` directory only after their contents have moved and all imports are updated.

### Cleanup and verification

- Update stale ownership comments under `home/config/**`.
- Classify or remove unreferenced `alacritty`, `fuzzel`, `mako`, `swaylock`, `gtk-2.0`, `gtk-3.0`, `gtk-4.0`, and `starship/mokka.toml` data only after reference checks.
- Keep `home/assets/` for genuinely shared assets; move software-specific Fastfetch logos and similar assets next to their software owner.

---

## Task 1: Establish the software-owner skeleton

**Files:**
- Create: `home/config/git/default.nix`, `home/config/fish/default.nix`, `home/config/zsh/default.nix`, `home/config/nushell/default.nix`.
- Create: `home/config/eza/default.nix`, `home/config/direnv/default.nix`, `home/config/zoxide/default.nix`, `home/config/starship/default.nix`, `home/config/bat/default.nix`, `home/config/tmux/default.nix`.
- Create: `home/config/mpv/default.nix`, `home/config/noctalia/default.nix`, `home/config/btop/default.nix`, `home/config/fastfetch/default.nix`, `home/config/helix/default.nix`, `home/config/kitty/default.nix`, `home/config/clangd/default.nix`, `home/config/toolchain/default.nix`, `home/config/niri/default.nix`, `home/config/fcitx5/default.nix`.
- Move: `home/nixvim/` to `home/config/nixvim/` without changing module contents.
- Modify: `home/default.nix`, `flake/default.nix`.

**Interfaces:**
- Each `default.nix` is a Home Manager module importable directly from `home/default.nix` or a feature module.
- A software module may use `programs.*`, `home.packages`, `xdg.configFile`, `home.file`, and `lib.mkAfter` only for that software.
- No new module may import a feature module; dependencies flow from features to software modules, never in reverse.

- [ ] **Step 1: Create the directory skeleton and move Nixvim.**

Create the directories listed above and move the existing `home/nixvim` tree into `home/config/nixvim`. Do not alter option bodies in this step. Keep raw configuration files in their existing software-named directories when they already match the target owner.

- [ ] **Step 2: Add direct imports for unchanged software owners.**

Use direct imports while preserving current behavior:

```nix
# home/default.nix
imports = [
  ./base.nix
  ./packages.nix
  ./config/git
  ./config/fish
  ./config/zsh
  ./config/nushell
  ./config/eza
  ./config/direnv
  ./config/zoxide
  ./config/starship
  ./config/bat
  ./config/tmux
  ./config/btop
  ./config/fastfetch
  ./config/helix
  ./config/toolchain
  ./scripts
];
```

Only include modules that are genuinely always-on. Kitty, MPV, Noctalia, Niri, Fcitx5, Clangd, and optional Nixvim remain feature imports until their feature boundary is migrated.

- [ ] **Step 3: Update Flake paths.**

Change `flake/default.nix` so `homeModules.nixvim` imports `../home/config/nixvim` and all public feature paths continue to resolve through their feature modules. Do not add compatibility aliases for deleted old paths.

- [ ] **Step 4: Run the skeleton evaluation.**

Run:

```bash
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
```

Expected: exit 0. Do not proceed if a moved path still points to `home/nixvim`.

---

## Task 2: Recompose Shell software and raw configuration

**Files:**
- Create or modify: `home/config/fish/default.nix`, `home/config/zsh/default.nix`, `home/config/nushell/default.nix`.
- Create or modify: `home/config/eza/default.nix`, `home/config/direnv/default.nix`, `home/config/zoxide/default.nix`, `home/config/starship/default.nix`, `home/config/bat/default.nix`, `home/config/tmux/default.nix`.
- Create: `home/config/shell/default.nix` for the intentionally shared `home.shellAliases` policy.
- Move or retain beside owners: `home/config/fish/**`, `home/config/zsh/**`, `home/config/nushell/**`, `home/config/starship/**`, `home/config/tmux/**`.
- Modify: `home/default.nix`, `home/config/fish/config.fish`, `home/config/zsh/.zshrc`, `home/config/nushell/config.nu`.
- Delete after migration: `home/shell.nix`.

**Interfaces:**
- `home/config/shell/default.nix` owns only cross-shell aliases that are meaningful in all enabled shells.
- Fish-specific abbreviations/functions remain under `config/fish`; Zsh completion and plugins remain under `config/zsh`; Nushell structured commands remain under `config/nushell`.
- Eza, Direnv, Zoxide, Starship, Bat, and Tmux declarations are not defined in shell modules.

- [ ] **Step 1: Move the native declarations without changing values.**

Split the existing `home/shell.nix` blocks by software. For example, `programs.eza` and its eza-specific aliases go to `config/eza/default.nix`; `programs.fish` and Fish file deployment go to `config/fish/default.nix`; `programs.tmux` and `tmux.conf` go to `config/tmux/default.nix`.

- [ ] **Step 2: Keep only shared aliases in the shell policy module.**

Preserve `home.shellAliases` as the single shared map, but remove entries for tools that are not part of the portable core unless their command is guaranteed by `home/packages.nix`. Keep shell-specific aliases in their native shell modules.

- [ ] **Step 3: Remove the generic deployment map.**

Move every `xdg.configFile` and `home.file` entry currently in `home/files.nix` into the owning module. Fish function discovery may remain dynamic inside `config/fish/default.nix`; no other software may be mapped from a catch-all file.

- [ ] **Step 4: Remove `home/shell.nix` and update imports.**

Delete the old module only after `home/default.nix` imports the new modules and no reference to `./shell.nix` remains.

- [ ] **Step 5: Run Shell syntax checks.**

Run:

```bash
fish -n home/config/fish/config.fish home/config/fish/conf.d/*.fish home/config/fish/functions/*.fish
bash -n home/scripts/*.sh
```

Expected: both commands exit 0.

---

## Task 3: Consolidate MPV, editor, terminal, and desktop software

**Files:**
- Create or modify: `home/config/mpv/default.nix`, `home/config/mpv/hold_forward.lua`, `home/config/mpv/patches/secure-uosc-post-patch.sh`.
- Create or modify: `home/config/fastfetch/default.nix`, `home/config/fastfetch/assets/**`, `home/config/btop/default.nix`, `home/config/helix/default.nix`, `home/config/kitty/default.nix`, `home/config/clangd/default.nix`, `home/config/toolchain/default.nix`.
- Move: `home/scripts/markdown-preview-bun-post-patch.sh` to `home/config/nixvim/patches/markdown-preview-bun-post-patch.sh`.
- Modify: `home/config/nixvim/plugins.nix`, `home/features/media.nix`, `home/features/desktop.nix`, `home/features/development.nix`.
- Delete after migration: `home/mpv.nix`, `home/programs.nix`.

**Interfaces:**
- `config/mpv/default.nix` is the only module that writes `programs.mpv.*`.
- `features/media.nix` imports `../config/mpv` and owns only unrelated media packages.
- `config/helix/default.nix` owns portable Helix files; NixOS-specific language extensions are added later by a platform overlay.
- `config/nixvim` remains optional and is imported only by `homeModules.nixvim` or a feature that explicitly needs it.

- [ ] **Step 1: Merge all MPV ownership.**

Move the full `home/mpv.nix` body into `home/config/mpv/default.nix`. Move `secureUosc` construction and MPV `scriptOpts` from `home/features/media.nix` into the same module. Use paths relative to `config/mpv` for the Lua file and patch script.

- [ ] **Step 2: Reduce `media.nix` to composition.**

Replace its MPV option block with:

```nix
imports = [ ../config/mpv ];
```

Retain only `mpd`, `ncmpcpp`, `ncspot`, `playerctl`, and `obs-studio` packages unless a later software module owns their settings.

- [ ] **Step 3: Give Fastfetch, Btop, Helix, Kitty, Clangd, and Toolchain owners.**

Move each corresponding `xdg.configFile`, package-specific assets, and `programs.*.enable` option from `files.nix`/`programs.nix` into its module. Kitty and Clangd must no longer be deployed by the portable core when their feature is disabled.

- [ ] **Step 4: Co-locate Nixvim build patches.**

Update the markdown-preview package override to read `./patches/markdown-preview-bun-post-patch.sh` from the Nixvim module. Keep the patch build-time only; do not expose it as a runtime executable.

- [ ] **Step 5: Delete superseded aggregators.**

Remove `home/mpv.nix` and `home/programs.nix` after grep confirms no imports or references remain. `home/files.nix` is removed only after Task 2 and this task have moved every mapping.

- [ ] **Step 6: Build the media and editor compositions.**

Run:

```bash
nix eval --impure --raw --expr '
  let f = builtins.getFlake (toString ./.);
      c = f.lib.mkHomeConfiguration {
        system = builtins.currentSystem;
        username = "media-probe";
        homeDirectory = "/tmp/media-probe";
        modules = [ f.homeModules.media ];
      };
  in c.config.home.homeDirectory
'
```

Expected: `/tmp/media-probe`. Repeat with `f.homeModules.nixvim`; both evaluations must succeed.

---

## Task 4: Consolidate Noctalia, Niri, Fcitx5, and desktop session ownership

**Files:**
- Create or modify: `home/config/noctalia/default.nix`, `home/config/niri/default.nix`, `home/config/fcitx5/default.nix`.
- Move or retain: `home/config/niri/*.kdl`, `home/config/fcitx5/**`.
- Modify: `home/features/niri.nix`, `home/features/desktop.nix`, `home/features/gaming.nix`, `home/features/theming.nix`.
- Modify: `home/config/noctalia/default.nix` to express the Noctalia package/plugin contract.

**Interfaces:**
- `config/noctalia` owns generated TOML and Noctalia-specific plugin settings.
- `config/niri` owns Niri KDL and compositor-only wrappers; it does not silently own unrelated desktop applications.
- `config/fcitx5` owns input-method configuration and required package declarations.
- `features/niri` explicitly imports the software modules required by its selected session.

- [ ] **Step 1: Move Noctalia generation unchanged.**

Move the `settings`, TOML generation, Taplo validation, and `xdg.configFile."noctalia/config.toml"` declaration from `home/noctalia.nix` to `home/config/noctalia/default.nix`. Keep the generated-file validation.

- [ ] **Step 2: Separate Niri from Noctalia.**

Move Niri KDL deployment and Niri-only wrappers into `config/niri/default.nix`. `features/niri.nix` imports both `../config/niri` and `../config/noctalia` and owns only the session-level package composition.

- [ ] **Step 3: Make input method ownership explicit.**

Move Fcitx5 files and package/session settings into `config/fcitx5`. Remove Fcitx5 file deployment from the Niri module. Desktop environment variables may remain in the Linux desktop capability module, but they must not imply that Niri owns Fcitx5.

- [ ] **Step 4: Resolve Niri command dependencies.**

Compare every executable referenced by `home/config/niri/binds.kdl` and related KDL files with the packages supplied by `features/niri`, `features/desktop`, `features/media`, and `features/gaming`. For each command, either import the owning software module, add the required package to the explicit session feature, or remove/gate the binding. Do not leave a public `homeModules.niri` with known broken bindings.

- [ ] **Step 5: Isolate host-specific outputs.**

Do not make fixed eDP-1/DP-1 connector and resolution data an unconditional portable default. Keep the current file as an explicit host override/example and make the Niri module deploy outputs only when the selected host supplies the override. Preserve the remaining portable Niri rules and bindings.

- [ ] **Step 6: Resolve Noctalia W Engine dependency.**

Verify whether `linux-wallpaperengine` is provided by the host or by Nix. If it is not declared, either add the explicit package/provisioning contract to the Noctalia/Niri feature or disable the W Engine settings instead of leaving an undeclared runtime dependency.

- [ ] **Step 7: Evaluate the Niri composition.**

Run a Nix evaluation that builds `f.homeModules.niri` and prints the package names. Confirm that all commands retained in the default bindings are available from the resulting package set or explicitly documented as host-provided.

---

## Task 5: Reduce feature modules to capability compositions

**Files:**
- Modify: `home/features/desktop.nix`, `development.nix`, `research.nix`, `china-apps.nix`, `theming.nix`, `gaming.nix`, `containers.nix`, `hardware.nix`, `observability.nix`, `security-tools.nix`, `terminal-tools.nix`, `nix-tools.nix`.
- Create software modules for application-specific desktop entries where needed, especially the Wemeet/Kazumi entries in `china-apps.nix` and Sioyek/Zotero/Obsidian entries in `research.nix`.
- Modify: `home/config/*/default.nix` imports as required.

**Interfaces:**
- A feature module may compose software modules and package groups, but an application desktop entry belongs to that application module.
- A feature's README-free contract is visible from its imports and package list; no feature may rely on an undeclared package from another feature.
- MIME/default-application policy remains in the scenario feature after software modules provide their desktop entries.

- [ ] **Step 1: Split desktop software from desktop capability.**

Move Kitty configuration into `config/kitty` and import it from the desktop feature. Keep application packages grouped only where the feature is intentionally a user-facing desktop bundle; do not let that bundle become the owner of unrelated software configuration.

- [ ] **Step 2: Split development software ownership.**

Keep toolchain package composition in `development.nix`, but import `config/helix`, `config/clangd`, and `config/toolchain` explicitly. Ensure portable Helix does not unconditionally receive NixOS-specific compiler paths.

- [ ] **Step 3: Split research and China application entries.**

Move each generated desktop entry next to the application it launches. Keep `research.nix` and `china-apps.nix` as compositions and document host-provided Flatpak requirements through assertions or explicit comments in the owning module.

- [ ] **Step 4: Separate theme and input-method ownership.**

Keep GTK/theme assets in `theming.nix` or `config/theme`, but remove Fcitx5 deployment from theme and Niri modules. Remove raw GTK files that conflict with Home Manager GTK settings only after confirming they are not deployed.

- [ ] **Step 5: Align Gaming and Niri.**

Move Steam package ownership to `gaming.nix`; let Niri import a small Steam launcher integration only if its session binds require it. Do not install Steam merely because the compositor is selected.

- [ ] **Step 6: Check feature isolation.**

For each public feature, evaluate a standalone Home Manager configuration with `nix eval`. A feature must not generate configuration for a binary it does not provide or explicitly document as host-provided.

---

## Task 6: Split NixOS platform overlays

**Files:**
- Create: `home/platform/nixos.nix`.
- Create or modify: `home/config/btop/nixos.nix`, `home/config/helix/nixos.nix`, `home/config/fish/nixos.nix`, `home/config/zsh/nixos.nix`, `home/config/nushell/nixos.nix`, `home/config/nixvim/nixos.nix`.
- Modify: `home/nixos.nix` or move its platform-only implementation into `home/platform/nixos.nix`.
- Modify: `flake/default.nix`.

**Interfaces:**
- `homeModules.nixos` remains the explicit platform entry point.
- `home/platform/nixos.nix` composes platform overlays and does not own portable defaults.
- Each software overlay modifies only its software's options/files.

- [ ] **Step 1: Move the NixOS factory and environment expressions.**

Move `flakeSourceExpression`, `nixpkgsExpression`, and `nixosOptionsExpression` into the platform module or a clearly named helper inside that module. Preserve the existing validation of `MCB_NIXOS_FLAKE_DIR` and `MCB_NIXOS_FLAKE_TARGET`.

- [ ] **Step 2: Move btop GPU integration to btop ownership.**

Place the NixOS btop wrapper in `config/btop/nixos.nix`. Avoid providing the same executable through both `home.packages` and `.local/bin` unless the precedence is intentional and tested; prefer one explicit package/path owner.

- [ ] **Step 3: Move shell and editor overlays to software owners.**

Move NixOS Fish functions, Zsh/Nushell additions, Helix language merge, and Nixvim nixd settings into their respective `nixos.nix` overlays. `home/platform/nixos.nix` imports them.

- [ ] **Step 4: Update the public path.**

Point `flake/default.nix` `homeModules.nixos` at the new platform entry point. Keep the Linux assertion and explicitly document that this module requires a NixOS host environment rather than generic Linux.

- [ ] **Step 5: Evaluate the NixOS composition.**

Run a synthetic NixOS Home Manager composition evaluation that checks the output contains the expected NixOS shell helpers, Helix language merge, and nixd settings without changing the portable default configuration.

---

## Task 7: Remove catch-all modules, orphan data, and stale ownership comments

**Files:**
- Delete: `home/files.nix`, `home/programs.nix`, and any superseded root software modules after reference checks.
- Modify: `home/config/niri/config.kdl`, `home/config/fcitx5/profile`, `home/config/btop/btop.conf`, `home/config/fastfetch/mokka.jsonc`, and other stale comments.
- Classify/remove only after reference checks: `home/config/alacritty/`, `fuzzel/`, `mako/`, `swaylock/`, `gtk-2.0/`, `gtk-3.0/`, `gtk-4.0/`, `starship/mokka.toml`.
- Move: Fastfetch logos and MPV/Nixvim-specific patches beside their owners.

**Interfaces:**
- No configuration file may claim ownership by a deleted module.
- Every retained raw file has one deployment path discoverable from its owning `default.nix`.
- Every removed file has no source or import reference in `home/` or `flake/`.

- [ ] **Step 1: Generate the reference inventory.**

Search all Nix and raw configuration files for each candidate path before deletion. Treat a raw file as active only when an import, `source`, `builtins.readFile`, or generated deployment path references it.

- [ ] **Step 2: Remove duplicate unused variants.**

Remove `starship/mokka.toml` only if no module reads it. Remove raw GTK files only if Home Manager `gtk` options are the sole active owner. Do not remove host-specific files that are explicitly retained as examples; rename them to make that role clear.

- [ ] **Step 3: Update comments and paths.**

Replace stale references to `files.nix`, `scripts.nix`, or old module paths with the owning software module path. Keep comments about host-specific outputs and host-provided commands explicit.

- [ ] **Step 4: Confirm no catch-all references remain.**

Run:

```bash
grep -RInE 'files\.nix|programs\.nix|home/(mpv|git|noctalia)\.nix|home/nixvim' home flake || true
```

Expected: no active import or deployment reference remains; historical comments are updated rather than ignored.

---

## Task 8: Full verification and delivery checkpoint

**Files:**
- Verify all modified Nix, Fish, Bash, and raw configuration paths.
- Modify `.agent/verify.md` only if commands or public module paths changed.

**Interfaces:**
- The portable default must build without optional desktop/media/development features.
- Each public feature must evaluate independently.
- NixOS/Niri runtime assumptions must be explicit; evaluation is not runtime proof.

- [ ] **Step 1: Format and parse.**

Run the repository formatter on all changed Nix files, then:

```bash
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
fish -n home/config/fish/config.fish home/config/fish/conf.d/*.fish home/config/fish/functions/*.fish
bash -n home/scripts/*.sh home/config/mpv/patches/*.sh home/config/nixvim/patches/*.sh
```

Expected: all commands exit 0.

- [ ] **Step 2: Run structural checks.**

```bash
nix flake check --impure --no-write-lock-file --show-trace
```

Expected: all checks pass.

- [ ] **Step 3: Build the portable default.**

```bash
env USER=alice HOME=/tmp/alice-final \
  home-manager build --impure --flake .#default --no-write-lock-file
```

Expected: exit 0 and an activation package is produced.

- [ ] **Step 4: Evaluate public features.**

Evaluate default, development, media, desktop, Niri, research, China apps, Nixvim, NixOS, and a full composition through `lib.mkHomeConfiguration`. Check each feature's expected `home.packages`, `xdg.configFile`, and software options rather than only checking that evaluation returns a derivation.

- [ ] **Step 5: Verify ownership invariants.**

Confirm:

```text
No home/files.nix or home/programs.nix remains.
No software has both a generic deployment owner and a dedicated deployment owner.
No feature writes programs.mpv, programs.git, or programs.noctalia outside the corresponding config module.
No portable module deploys NixOS-only clangd, Helix, btop, or wrapper paths.
No retained raw file lacks a source/import reference.
```

- [ ] **Step 6: Record remaining runtime limits.**

Run available Fish/Zsh startup smoke checks. Report separately if Zsh, Niri, Noctalia, a NixOS host, or the required GUI binaries are unavailable; do not call evaluation success runtime proof.

- [ ] **Step 7: Review the final change set.**

Inspect the complete file list for accidental deletions, duplicate imports, broken relative paths, stale comments, host-specific data in portable modules, and missing feature dependencies. Only after this review should the architecture commit and the previously requested GitHub publication/archive workflow resume.

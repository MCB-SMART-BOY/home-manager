# Home Manager cleanup implementation plan

## Goal

Make the repository Nix-first, keep `allowUnfree` true, centralize compatible aliases through Home Manager, isolate real runtime scripts under `home/scripts/`, and expose one coherent optional feature namespace.

## Task 1 — Flake boundary

Modify `flake/default.nix` and `flake.nix` using the current two-space style.

- Fix the top-level description typo.
- Keep Linux system generation and the thin flake entry.
- Make `mkPkgs` always import nixpkgs with `config.allowUnfree = true`.
- Expose `modules ? []` as the only public extension argument.
- Remove the public `allowUnfree` argument and every false override.
- Keep the explicit impure default environment error.
- Remove duplicate Home Manager CLI packages/apps and checks that only inspect an activation file.
- Export only the actual configuration modules plus formatter and meaningful checks.

## Task 2 — Nix-owned shell behavior

Modify `home/shell.nix`, `home/files.nix`, `home/packages.nix`, and approved raw alias/integration blocks under `home/config/fish` and `home/config/zsh`.

- Add one `home.shellAliases` map for simple cross-shell aliases.
- Set `programs.fish.preferAbbrs = true`.
- Use `programs.eza` for Eza aliases and native integration options for Starship, Zoxide, and Direnv.
- Remove duplicated alias and integration blocks from raw Fish/Zsh files.
- Stop force-replacing Home Manager's generated Fish config; feed the remaining Fish config as `interactiveShellInit`.
- Keep shell-specific functions, Fish-only abbreviations, Zsh completion, and Nushell structured commands in their native files/options.
- Remove runtime alias cleanup fragments.

## Task 3 — Script boundary

Move the real toolchain implementation from `home/scripts.nix` into `home/scripts/mcb-toolchain` and use `home/scripts/default.nix` as the short Nix module. Remove the Fastfetch runtime wrapper because the existing Fastfetch glob configuration already selects logos. Keep only short Nix wrappers for genuinely required host integration.

## Task 4 — Feature ownership

Move package-only profiles into cohesive `home/features/*.nix` modules. Make `home/features` the only public optional namespace. Remove pass-through wrappers, the unused Linux module, stale commented WinBoat code, and obsolete comments. Ensure Niri's package/config/service dependencies are explicit rather than accidentally inherited.

## Verification

- Use Nix evaluation probes for the public factory, `allowUnfree`, shared alias output, and feature composition.
- Run the standalone default build and `nix flake check`.
- Evaluate development, research, China-apps, security, Niri, and NixOS compositions.
- Check no Nix file contains a runtime shell body over three lines except unavoidable data/build glue; longer runtime programs must be files under `home/scripts/`.
- Recompute `home/config` and `home/assets` hashes and report the intentional alias/integration source changes.

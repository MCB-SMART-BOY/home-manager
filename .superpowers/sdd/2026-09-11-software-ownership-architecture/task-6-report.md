# Task 6 Report — Split NixOS platform overlays

## Status

PASS. NixOS is now an explicit platform entry point, while portable defaults remain usable without the platform module. The former monolithic `home/nixos.nix` implementation was moved to `home/platform/nixos.nix` and split into software-owned NixOS overlays.

## Boundary and ownership map

- `flake/default.nix`
  - `homeModules.nixos` now points to `../home/platform/nixos.nix`.
  - The public path comment documents that this is for an explicit NixOS host, not generic Linux.
- `home/platform/nixos.nix`
  - Owns the NixOS-only composition boundary, Linux assertion, NixOS-host assertion, `/run/wrappers/bin` session path, and the factory expressions passed to platform overlays.
  - Imports each platform overlay and does not define portable software defaults.
  - Preserves `MCB_NIXOS_FLAKE_DIR` absolute-path, URI-scheme, query/fragment, and existence validation.
  - Preserves `MCB_NIXOS_FLAKE_TARGET`/`NIXD_HOST`/hostname/unique-target selection behavior.
- `home/config/btop/nixos.nix`
  - Owns the OpenGL-driver btop wrapper through `programs.btop.package`.
  - Does not add a second `.local/bin/btop` home-file provider.
- `home/config/fish/nixos.nix`
  - Owns NixOS Fish function deployment only.
- `home/config/zsh/nixos.nix`
  - Owns NixOS Zsh init content and NixOS aliases only.
- `home/config/nushell/nixos.nix`
  - Owns NixOS Nushell extra configuration only.
- `home/config/helix/nixos.nix`
  - Owns the NixOS Helix language merge and Nix store `--query-driver` addition.
  - Portable `home/config/helix/languages.toml` remains free of NixOS compiler paths.
- `home/config/nixvim/nixos.nix`
  - Owns NixOS `nixd` expressions and NixOS clangd `--query-driver` configuration.
  - Portable `home/config/nixvim/lsp.nix` remains free of the Nix store compiler glob.
- `home/nixos.nix`
  - Removed after all imports and the public flake path moved to the platform entry point.

## Commits

- `181605b1dc861680ae4b0aa09413dcfd3047a0d8` — `refactor: split NixOS platform overlays`
- `6ca28c3168de69c47775bf695663f9206895ad27` — `fix: keep Nixvim platform flags out of portable config`

The pre-existing unstaged correction to `.superpowers/sdd/2026-09-11-software-ownership-architecture/task-3-report.md` was not modified or included.

## Verification

No formatter, linter, or project-wide test/build suite was run, as required. The following focused checks were run from the worktree.

### Focused Nix parse

Command:

```bash
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
```

Result: PASS (exit 0; no parse error).

### Focused whitespace check

Command:

```bash
git diff --check
```

Result: PASS (exit 0).

### Synthetic NixOS composition evaluation

The composition included both public platform and Nixvim modules so that all requested platform-owned behavior was exercised:

```bash
nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); c = f.lib.mkHomeConfiguration { system = builtins.currentSystem; username = "nixos-platform-probe"; homeDirectory = "/tmp/nixos-platform-probe"; modules = [ f.homeModules.nixos f.homeModules.nixvim ]; }; helixText = builtins.readFile c.config.xdg.configFile."helix/languages.toml".source; clangd = c.config.programs.nixvim.lsp.servers.clangd.config.cmd; nixd = c.config.programs.nixvim.lsp.servers.nixd.config.settings.nixd; in { helixQueryDriver = builtins.match ".*query-driver.*" helixText != null; nixvimQueryDriver = builtins.any (arg: builtins.match ".*query-driver.*" arg != null) clangd; nixvimNixd = nixd.nixpkgs.expr != "" && nixd.options.nixos.expr != ""; }'
```

Result: PASS (exit 0):

```json
{"helixQueryDriver":true,"nixvimNixd":true,"nixvimQueryDriver":true}
```

Additional ownership checks in the same focused composition evaluation confirmed:

```text
hasNixosFunctions=true
hasZshHelpers=true
hasNushellHelpers=true
btopPackage="btop"
btopLocalFile=false
```

The btop package path resolves to the generated wrapper, whose script exports `/run/opengl-driver/lib` and executes the Nixpkgs btop binary; no `.local/bin/btop` home-file entry is generated.

### Portable-default boundary evaluation

Command:

```bash
nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); c = f.lib.mkHomeConfiguration { system = builtins.currentSystem; username = "portable-probe"; homeDirectory = "/tmp/portable-probe"; modules = [ f.homeModules.nixvim ]; }; in { portableQueryDriver = builtins.match ".*query-driver.*" (builtins.readFile c.config.xdg.configFile."helix/languages.toml".source) != null; portableNixvimQueryDriver = builtins.any (arg: builtins.match ".*query-driver.*" arg != null) c.config.programs.nixvim.lsp.servers.clangd.config.cmd; }'
```

Result: PASS (exit 0):

```json
{"portableNixvimQueryDriver":false,"portableQueryDriver":false}
```

A portable default evaluation also confirmed the normal btop package remains `btop-1.4.7` and no NixOS Fish function is present:

```text
portableBtopPackage="btop-1.4.7"
portableHasNixosFish=false
portableQueryDriver=false
```

### Factory-expression preservation

The synthetic composition was inspected for the platform-provided expressions. Focused checks returned:

```json
{"nixpkgsExpressionHasSchemeValidation":true,"nixpkgsExpressionHasSourceValidation":true,"optionsExpressionHasHostSelection":true,"optionsExpressionHasTargetValidation":true}
```

These checks matched the preserved validation strings for `MCB_NIXOS_FLAKE_DIR`, `MCB_NIXOS_FLAKE_TARGET`, and `NIXD_HOST`.

## Runtime limitation

This worktree runs on a NixOS host: `/etc/NIXOS` and `/run/current-system` were present, and `nixos-rebuild` was available. No `nixos-rebuild` activation, system rebuild, shell startup session, Helix GUI/editor session, or Nixvim runtime was run. The evidence above is therefore composition/evaluation proof, not proof of activation or interactive runtime behavior. The platform module intentionally asserts `/etc/NIXOS`, so a generic Linux host is expected to reject `homeModules.nixos`; portable modules remain the supported path there.

## Concerns

- The Nixvim platform overlay uses `lib.mkForce` for the complete clangd command so the portable command is retained while adding the NixOS query-driver. A downstream platform consumer that needs a different clangd command must override this option deliberately.
- The NixOS factory expressions evaluate host flake paths and NixOS target selection when nixd invokes them. The synthetic Home Manager evaluation verifies that the expressions are present and retain validation, but does not invoke a real external host flake target.
- Existing unrelated unstaged changes remain in `task-3-report.md`; they are intentionally outside this Task 6 commit.

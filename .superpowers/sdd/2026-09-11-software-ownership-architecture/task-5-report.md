# Task 5 Report — Reduce feature modules to capability compositions

## Status

PASS. Task 5 feature modules now compose explicit software owners and capability package groups. Application-specific desktop entries and packages were moved into dedicated owners, Steam is owned by gaming while Niri retains only its launcher integration, development imports Helix/Clangd/toolchain explicitly, and obsolete raw GTK files are no longer deployed.

## Changed files

- `home/config/sioyek/default.nix`, `zotero/default.nix`, `obsidian/default.nix`
  - Added software owners containing each research application's package and desktop entry.
- `home/config/bilibili/default.nix`, `clash-nyanpasu/default.nix`, `clash-verge/default.nix`, `wemeet/default.nix`
  - Added software owners containing each package and generated desktop entry.
- `home/config/kazumi/default.nix`
  - Added the Kazumi launcher entry. The Flatpak remains host-provided and is documented in the owner comment; the module does not pretend to install the application.
- `home/features/research.nix`
  - Imports Sioyek/Zotero/Obsidian owners, retains research capability packages, and retains MIME/default-application policy.
- `home/features/china-apps.nix`
  - Imports application owners and retains only capability packages (`metacubexd`, `ani-cli`, `mangayomi`).
- `home/features/development.nix`
  - Explicitly imports `config/helix`, `config/clangd`, and `config/toolchain`.
- `home/features/gaming.nix`
  - Owns the Steam package alongside the existing Wine capability packages.
- `home/config/niri/default.nix`
  - Removes Steam package ownership while preserving the `steam-launcher` wrapper and binding integration.
- `home/features/niri.nix`
  - Documents that Steam is supplied by gaming or the host; Niri continues to provide session-level application packages and imports its required software owners.
- `home/features/theming.nix`
  - Removes Fcitx5 deployment from theme configuration while preserving GTK theme assets/options.
- `home/config/gtk-2.0/gtkrc`, `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`
  - Removed after reference search confirmed no active deployment path; Home Manager GTK options are the active theme owner.

`home/nixos.nix`, `home/platform`, and `.superpowers/sdd/2026-09-11-software-ownership-architecture/task-3-report.md` were not intentionally changed. The pre-existing unstaged `task-3-report.md` correction remains in the worktree and is excluded from the Task 5 commits.

## Verification

Focused syntax check:

```text
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
PASS (exit 0)
```

Focused whitespace check:

```text
git diff --check
PASS (exit 0)
```

Standalone feature evaluations, each with `nix eval --impure --raw --expr 'let f = builtins.getFlake (toString ./.); c = f.lib.mkHomeConfiguration { system = builtins.currentSystem; username = "<feature>-probe"; homeDirectory = "/tmp/<feature>-probe"; modules = [ f.homeModules.<feature> ]; }; in c.config.home.homeDirectory'`:

```text
default        /tmp/default-probe
 desktop       /tmp/desktop-probe
 development   /tmp/development-probe
 media         /tmp/media-probe
 research      /tmp/research-probe
 gaming        /tmp/gaming-probe
 china-apps    /tmp/china-probe
 niri          /tmp/niri-probe
 theming       /tmp/theming-probe
 containers    /tmp/containers-probe
 hardware      /tmp/hardware-probe
 observability /tmp/observability-probe
 security-tools /tmp/security-probe
 terminal-tools /tmp/terminal-probe
 nix-tools     /tmp/nix-probe
 nixvim        /tmp/nixvim-probe
```

Ownership/isolation probe:

```text
nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); mk = name: f.lib.mkHomeConfiguration { system = builtins.currentSystem; username = "isolation-probe"; homeDirectory = "/tmp/isolation-probe"; modules = [ f.homeModules.${name} ]; }; niri = mk "niri"; gaming = mk "gaming"; development = mk "development"; theming = mk "theming"; hasSteam = c: builtins.any (p: (p.pname or "") == "steam") c.config.home.packages; in { niriSteam = hasSteam niri; niriSteamLauncher = builtins.hasAttr ".local/bin/steam-launcher" niri.config.home.file; gamingSteam = hasSteam gaming; developmentConfig = builtins.filter (path: builtins.match "(clangd|helix|toolchain)/.*" path != null) (builtins.attrNames development.config.xdg.configFile); themingFcitx = builtins.filter (path: builtins.match "fcitx5/.*" path != null) (builtins.attrNames theming.config.xdg.configFile); }'
PASS (exit 0): {"developmentConfig":["clangd/config.yaml","helix/config.toml","helix/languages.toml","toolchain/tools.json"],"gamingSteam":true,"niriSteam":false,"niriSteamLauncher":true,"themingFcitx":[]}
```

Portable Helix boundary probe:

```text
grep -n -- '--query-driver' home/config/helix/languages.toml
no output (exit 1; expected — portable Helix contains no NixOS compiler path)
```

Observed invariants: development includes Helix, Clangd, and toolchain config paths; gaming includes Steam; Niri has `steam-launcher` but does not include the Steam package; theming has no Fcitx5 config deployment; research and China apps expose their owner-provided desktop entries; Kazumi is represented as a host-provided Flatpak launcher.

No formatter, linter, project-wide test suite, Home Manager activation/build, or GUI runtime session check was run, as required. Niri/Noctalia, Flatpak Kazumi, and desktop application launch behavior therefore remain runtime-unverified.

## Commits

- `741a917` — `refactor: compose capability features`
- `6493f95` — `fix: keep portable helix compiler settings generic`

## Follow-up correction

Reviewer follow-up identified a portable-boundary issue: `home/config/helix/languages.toml` previously supplied a Nix store glob through clangd's `--query-driver` argument. That compiler path is NixOS/platform-specific, so it was removed from the portable Helix owner; Task 6's platform overlay may add it where appropriate. The follow-up also replaced the earlier report's placeholder ownership probe with the exact command and output above.

## Concerns

- The requested `task-5-context.md` is in the shared ledger at `/home/admin/.config/home-manager/.superpowers/sdd/2026-09-11-software-ownership-architecture/task-5-context.md`, not inside this linked worktree. Its boundaries were followed.
- The Niri Steam binding still depends on Steam being supplied by the gaming feature or host; selecting only `homeModules.niri` intentionally does not install Steam.
- Kazumi remains host-provided via Flatpak; evaluation verifies launcher generation, not that the Flatpak is installed or launchable.

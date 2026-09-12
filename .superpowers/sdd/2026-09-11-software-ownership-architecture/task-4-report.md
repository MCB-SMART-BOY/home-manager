# Task 4 Report — Consolidate Noctalia, Niri, Fcitx5, and desktop session ownership

## Status

PASS. Noctalia, Niri, and Fcitx5 declarations now live beside their software data. The Niri feature explicitly composes the session owners and provides the commands retained by its default bindings. Machine-specific output deployment is opt-in, while the portable Niri entry uses an optional output include for automatic display detection.

## Changed files

- `home/config/noctalia/default.nix`
  - Moved the complete Noctalia v5 settings, TOML generation, and Taplo validation from the legacy module.
  - Noctalia owns the v5 `noctalia` package, `linux-wallpaperengine`, and the wallpaper assets required by its wallpaper settings.
- `home/config/niri/default.nix`
  - Added Niri KDL deployment, compositor/session wrappers (`niri-run`, `lock-screen`, and `steam-launcher`), and Niri's compositor package dependencies.
  - Added `mcb.niri.hostOutputs.enable`; `outputs.kdl` is deployed only when this host override is selected.
- `home/config/niri/config.kdl`
  - Removed the unconditional machine-specific output assumption.
  - Added an optional `outputs.kdl` include and documented the host override contract, W Engine executable ownership, and terminal fallback.
- `home/config/niri/binds.kdl`
  - Corrected the Telegram binding to use the package's actual `Telegram` executable.
- `home/config/fcitx5/default.nix`
  - Added Fcitx5, Rime, the Qt6 Chinese addons required by the profile's `pinyin` input method, GTK, and Qt package ownership; deployed the Fcitx5 profile/classic UI files.
- `home/config/fcitx5/profile`
  - Updated the ownership comment to the new module path.
- `home/features/niri.nix`
  - Imports `config/niri`, `config/noctalia`, `config/fcitx5`, and Kitty explicitly.
  - Adds direct dependencies for all default desktop, media, and screenshot bindings: Nautilus, Chrome, Telegram, OBS, pavucontrol, KeePassXC, Mission Center, playerctl, grim, slurp, wl-clipboard, and satty, plus the existing session tools.
  - Contains no Fcitx5 or Niri/Noctalia file deployment.
- `home/noctalia.nix`
  - Deleted after migration; no active source references remain.

`home/nixos.nix`, `home/platform`, and unrelated feature cleanup were not modified. The pre-existing reviewed metadata correction in `task-3-report.md` was left untouched.

## Dependency and boundary findings

- Niri's direct default bindings are covered by packages in the standalone Niri composition. Package executable names verified for the non-obvious commands include `google-chrome-stable`, `missioncenter`, `obs`, `playerctl`, `grim`, `slurp`, `satty`, and `Telegram`; the Niri feature's `niri-run` wrapper provides the shell path used by shell pipelines and `${TERMINAL:-kitty}`.
- `linux-wallpaperengine` is available in the selected nixpkgs package set and is explicitly installed by the Noctalia owner. No host-provided W Engine dependency is left implicit.
- `outputs.kdl` retains the fixed eDP-1/DP-1 example, but it is not deployed by default. Hosts that need it must enable `mcb.niri.hostOutputs.enable`; otherwise Niri's optional include permits automatic output detection.
- Fcitx5 environment variables remain in `home/desktop.nix`, while files and package ownership are in `config/fcitx5`.

## Verification

Required parse check:

```text
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
PASS (exit 0)
```

Required standalone Niri evaluation (baseline):

```text
nix eval --impure --raw --expr '... f.homeModules.niri ...'
/tmp/niri-probe (exit 0)
```

The baseline command only proved that the standalone module evaluated and returned the requested home directory. The follow-up verification below forces package and file attributes and checks both output modes.

Focused checks:

- Legacy `home/noctalia.nix` is absent and no active source under `home`, `flake.nix`, or `flake` references it: PASS.
- `features/niri.nix` has no Fcitx5 deployment or duplicated Niri/Noctalia config mapping: PASS.
- `home/config/niri/config.kdl`, `rules.kdl`, `binds.kdl`, `outputs.kdl`, `home/config/fcitx5/profile`, and `classicui.conf` all exist: PASS.
- `linux-wallpaperengine` package identity and executable were confirmed from nixpkgs metadata: PASS.

Follow-up forced composition verification:

```text
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
PASS (exit 0)

nix eval --impure --json --expr '... f.homeModules.niri ... plain + { mcb.niri.hostOutputs.enable = true; } ...'
PASS (exit 0)
```

The forced evaluation returned `/tmp/niri-probe` for both configurations, verified all six portable config files in both configurations, verified `niri/outputs.kdl` is absent in the plain configuration and present when `mcb.niri.hostOutputs.enable = true`, and confirmed the Niri session package set contains `noctalia`, `linux-wallpaperengine`, Fcitx5/Rime/Chinese addons/GTK/Qt, Kitty, and every retained default-binding executable package.

No formatter, linter, or project-wide test suite was run, per the brief.

`ed3452b` — `refactor: consolidate niri session ownership`.

This report was updated in the follow-up fix round; the focused follow-up commit records corrections to the conditional output mapping, Noctalia v5 package ownership, and the declared Fcitx5 Pinyin provider.

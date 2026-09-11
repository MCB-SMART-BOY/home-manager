# Task 8 Report — Full verification and delivery checkpoint

## Status

**PASS with explicitly recorded runtime limitations.** The architecture gate was run from the `software-ownership-architecture` worktree. The portable default parsed, passed the flake checks, and produced a Home Manager activation package. Every public feature evaluated independently with meaningful package/option/file probes, and the full composition evaluated successfully. No production bug was found, so no production fix was made.

The pre-existing unstaged correction to `task-3-report.md` was left untouched and is not included in this report commit.

## Inputs and baseline

- Worktree: `/home/admin/.config/home-manager/.worktrees/software-ownership-architecture`
- Baseline architecture commit at the beginning of this gate: `0d709a615e9a914fd5ac77148808445e147e0b61` (`fix: clarify Task 7 ownership report`)
- The requested worktree copy of `task-8-context.md` was absent. The same context file was located and read at the parent repository path `/home/admin/.config/home-manager/.superpowers/sdd/2026-09-11-software-ownership-architecture/task-8-context.md`.
- Initial repository state contained only the known pre-existing change:
  ` M .superpowers/sdd/2026-09-11-software-ownership-architecture/task-3-report.md`

## Gate 1 — Formatter and syntax parsing

### Formatter

The repository formatter is the flake formatter (`nixfmt` 1.4.0).

Initial command:

```bash
nix fmt
```

Result: **exit 1**. The bare invocation attempted to format empty stdin and reported:

```text
Warning: Bare invocation of nixfmt is deprecated. Use 'nixfmt -' for anonymous stdin.
<stdin>:1:1:
  |
1 | <empty line>
  | ^
unexpected end of input
expecting expression
```

No source file was changed by that failed invocation. The formatter was then run with explicit repository paths:

```bash
nix fmt -- flake/default.nix home/default.nix home/features/*.nix home/config/**/*.nix home/platform/nixos.nix
```

Result: **exit 0**.

A complete explicit Nix path pass was also run:

```bash
bash -O globstar -c 'nix fmt -- flake.nix flake/**/*.nix home/**/*.nix'
```

Result: **exit 0**.

Formatter review found only three formatter changes:

- `home/config/fcitx5/default.nix`: removed an extra blank line.
- `home/config/helix/nixos.nix`: formatter indentation/layout only; the NixOS query-driver string and replacement behavior are unchanged.
- `home/config/niri/default.nix`: formatter-expanded argument layout and expression wrapping only; package, file, and `hostOutputs` behavior are unchanged.

No semantic production fix was needed.

### Nix parse

```bash
bash -O globstar -c 'nix-instantiate --parse flake.nix flake/default.nix home/**/*.nix'
```

Result: **exit 0**; all targeted Nix expressions parsed without an error.

### Fish parse

```bash
fish -n home/config/fish/config.fish home/config/fish/conf.d/*.fish home/config/fish/functions/*.fish
```

Result: **exit 0**.

### Bash parse

The exact brief command was attempted first:

```bash
bash -n home/scripts/*.sh home/config/mpv/patches/*.sh home/config/nixvim/patches/*.sh
```

Result: **exit 127**, because this repository has no `home/scripts/*.sh` files; the runtime shell script is the extensionless `home/scripts/mcb-toolchain`. This was a path/glob mismatch in the brief, not a syntax error.

The available scripts were then parsed with:

```bash
bash -n home/scripts/mcb-toolchain home/config/mpv/patches/*.sh home/config/nixvim/patches/*.sh
```

Result: **exit 0**, with no output.

## Gate 2 — Structural flake checks

```bash
nix flake check --impure --no-write-lock-file --show-trace
```

Result: **exit 0**.

Relevant output:

```text
evaluating flake...
checking flake output 'lib'...
checking flake output 'homeModules'...
checking flake output 'homeConfigurations'...
checking flake output 'checks'...
checking derivation checks.x86_64-linux.home-configuration...
derivation evaluated to /nix/store/c929kqn4054vv253vrzflgplndmlgi5r-home-manager-generation.drv
checking flake output 'formatter'...
checking derivation formatter.x86_64-linux...
derivation evaluated to /nix/store/x7zzz4gil4fb52mwmh8ah431kyk5g9wg-nixfmt-1.4.0.drv
running 2 flake checks...
all checks passed!
```

The command reported that incompatible systems were omitted (`aarch64-linux`, `armv6l-linux`, `armv7l-linux`, `i686-linux`, `powerpc64le-linux`, `riscv64-linux`), as expected from the flake's Linux system filter.

## Gate 3 — Portable default Home Manager build

```bash
env USER=alice HOME=/tmp/alice-final \
  home-manager build --impure --flake .#default --no-write-lock-file
```

Result: **exit 0**. The two Home Manager files/generation derivations built successfully. The resulting activation package was resolved as:

```text
/nix/store/j1ia5mcmikvnppr9j0x1y1fg1mql4zpw-home-manager-generation
```

The build emitted only the normal dirty-tree warning and Home Manager news-count notice; no build error occurred.

## Gate 4 — Independent public-feature evaluation

The following probe used `lib.mkHomeConfiguration` for each public module. Package checks inspect `pname`/`name`; file checks inspect `xdg.configFile`/`xdg.dataFile`; option checks inspect the corresponding Home Manager option. Every `expected` result was `true`.

The compact probe command was:

```bash
nix eval --impure --raw --expr '<mkHomeConfiguration probe expression covering default, desktop, development, media, niri, research, china-apps, nixvim, nixos, gaming, theming, containers, hardware, observability, security-tools, nix-tools, terminal-tools, and the full composition>'
```

The evaluated expression constructed each module independently with:

```nix
f.lib.mkHomeConfiguration {
  system = builtins.currentSystem;
  username = "task8-probe";
  homeDirectory = "/tmp/task8-probe";
  modules = [ f.homeModules.<feature> ];
}
```

Meaningful probe results:

```text
default: PASS, packages=33
  coreutils/ripgrep present; programs.git.enable; programs.fish.enable; programs.zsh.enable

desktop: PASS, packages=51
  nautilus present; kitty/kitty.conf deployed; GTK_IM_MODULE=fcitx

development: PASS, packages=58
  rustup present; programs.helix.enable; clangd/config.yaml deployed

media: PASS, packages=39
  programs.mpv.enable; video-sync=display-resample; obs-studio present

niri: PASS, packages=70
  niri and noctalia packages present; niri/config.kdl and noctalia/config.toml deployed

research: PASS, packages=49
  sioyek and zotero present; PDF default application is sioyek.desktop

china-apps: PASS, packages=44
  bilibili and wemeet present; clash-verge desktop entry present

nixvim: PASS, packages=34
  programs.nixvim.enable; clangd LSP enabled; blink-cmp enabled

nixos: PASS, packages=33
  /etc/NIXOS present; NixOS Fish function deployed; platform session path evaluated

gaming: PASS, packages=36
  steam and winetricks present

theming: PASS, packages=38
  GTK enabled; Catppuccin theme data deployed

containers: PASS, packages=36
  distrobox and firecracker present

hardware: PASS, packages=48
  nvme-cli and fwupd present

observability: PASS, packages=46
  bpftrace and valgrind present

security-tools: PASS, packages=43
  burpsuite and gitleaks present

nix-tools: PASS, packages=40
  nh and nurl present

terminal-tools: PASS, packages=36
  zellij and jujutsu present

full composition: PASS, packages=205
  desktop, development, media, Niri, research, China apps, Nixvim, and NixOS probes all true
```

The evaluator emitted the existing upstream warning that LibreOffice versioning should use `libreoffice-stable`; this is an upstream package warning and did not fail evaluation.

## Gate 5 — Ownership invariants

Repository searches used the repository search tool rather than shell `grep`/`rg`.

### Catch-all modules

Search pattern:

```text
home/(files|programs|mpv|git|noctalia)\.nix|home/nixvim
```

Search scope: `home/` and `flake/`.

Result: **no matches**. `home/files.nix` and `home/programs.nix` are absent, and no old root-module imports remain.

### Dedicated program owners

Search pattern:

```text
programs\.(mpv|git|noctalia)
```

Result: `programs.git` occurs only in `home/config/git/default.nix`; `programs.mpv` occurs only in `home/config/mpv/default.nix`; no `programs.noctalia` declaration occurs. Feature files import these owners rather than redeclaring their options.

### NixOS-only paths excluded from portable modules

Searches for `/nix/store/`, `/run/opengl-driver`, `/run/wrappers`, `query-driver`, and platform wrapper declarations showed these only in the explicit NixOS overlay paths:

- `home/config/btop/nixos.nix`
- `home/config/helix/nixos.nix`
- `home/config/nixvim/nixos.nix`
- `home/config/fish/nixos.nix`
- `home/config/zsh/nixos.nix`
- `home/config/nushell/nixos.nix`

Portable `home/default.nix`, generic `home/config/btop/default.nix`, generic `home/config/helix/*`, and generic Nixvim LSP configuration do not contain the NixOS compiler glob or `/run` wrapper paths. The NixOS composition probe confirmed the platform overlays separately; the portable default build does not import `home/platform/nixos.nix`.

### Raw-file ownership

The retained raw assets all have an owning `source`, `builtins.readFile`, generated-file, or explicit import reference beside their software owner. The Task 7 inventory was rechecked against the current tree: Fastfetch logos, MPV Lua/patch assets, Nixvim patch assets, Fcitx5 profile/config, Niri KDL files, Helix TOML files, shell startup/function files, and theme/wallpaper data each have active owner references. The previously identified orphan files remain absent.

## Gate 6 — Shell and runtime smoke checks

### Fish

Isolated startup smoke:

```bash
tmp=$(mktemp -d); HOME="$tmp" XDG_CONFIG_HOME="$tmp/.config" TERM=dumb \
  fish -ic 'status is-interactive; type -q fastfetch; functions -q mkcd; functions -q nfu; echo fish-startup-ok'; \
  status=$?; rm -rf "$tmp"; exit "$status"
```

Result: **exit 0**, output:

```text
fish-startup-ok
```

Repository-config smoke:

```bash
tmp=$(mktemp -d); HOME="$tmp" XDG_CONFIG_HOME="$PWD/home/config" TERM=dumb \
  fish -ic 'functions -q mkcd; functions -q extract; functions -q fcd; type -q fastfetch; echo fish-repo-config-ok'; \
  status=$?; rm -rf "$tmp"; exit "$status"
```

Result: **exit 0**, output:

```text
fish-repo-config-ok
```

### Zsh and desktop runtime limits

- `zsh`: **unavailable** on this verification host; the attempted smoke check reported `zsh unavailable` and exited 127. No Zsh runtime claim is made.
- `niri`: binary available at `/run/current-system/sw/bin/niri`, but no graphical Niri session was launched.
- `noctalia-session`: unavailable; no Noctalia GUI/session smoke was possible.
- No GUI application launch, Home Manager activation, NixOS rebuild, or desktop compositor session was run in this gate.
- `/etc/NIXOS` is present, so the NixOS module's host assertion evaluated successfully. This is evaluation evidence only, not proof of a host rebuild or activation.
- Evaluation/build success is not treated as interactive runtime proof for Niri, Noctalia, systemd user services, GUI applications, or host-provided wrapper commands.

## Gate 7 — Final change-set review

The formatter diff was reviewed for semantic safety. It changes only whitespace/layout in the three Nix files listed above. No imports, option names, package lists, source paths, generated file paths, or platform boundaries changed.

Before staging, the worktree contained:

```text
 M .superpowers/sdd/2026-09-11-software-ownership-architecture/task-3-report.md
 M home/config/fcitx5/default.nix
 M home/config/helix/nixos.nix
 M home/config/niri/default.nix
```

Only the three formatter files and this report are to be staged. `task-3-report.md` remains intentionally unstaged and excluded.

## Commits

- Baseline verified architecture commit: `0d709a615e9a914fd5ac77148808445e147e0b61`
- Task 8 delivery commit: `eb99b7fc815867311651b3a32d9e34168a32cbe8` — `chore: complete Task 8 verification gate`

The delivery commit contains only the formatter changes and this report. The pre-existing `task-3-report.md` correction remains unstaged and excluded.

## Unresolved risks

1. Zsh startup remains runtime-unverified because `zsh` is unavailable on the host.
2. Niri/Noctalia and GUI application behavior remains runtime-unverified because no graphical session was launched and `noctalia-session` is unavailable.
3. NixOS platform behavior was evaluated on a host exposing `/etc/NIXOS`, but no activation or `nixos-rebuild` was run.
4. The Bash command in the brief names `home/scripts/*.sh`, while the repository's active `home/scripts/mcb-toolchain` is extensionless; the corrected available-script parse passed.
5. The existing upstream LibreOffice package warning recommends `libreoffice-stable`; it did not affect evaluation or the build and was not changed in this verification-only task.

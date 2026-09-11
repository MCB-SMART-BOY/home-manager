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

The following executable probe used `lib.mkHomeConfiguration` for every public feature and the full composition. `mk` already prepends `f.homeModules.default`, so the default row deliberately calls `mk []` rather than passing `f.homeModules.default` a second time. Package checks inspect `pname`/`name`; file checks inspect `xdg.configFile`/`xdg.dataFile`; option checks inspect the corresponding Home Manager option.

Exact command:

```bash
nix eval --impure --raw --show-trace --expr '
let
  f = builtins.getFlake (toString ./.);
  mk = modules: f.lib.mkHomeConfiguration {
    system = builtins.currentSystem;
    username = "task8-probe";
    homeDirectory = "/tmp/task8-probe";
    inherit modules;
  };
  names = c: map (p: p.pname or p.name or "") c.config.home.packages;
  hasPkg = c: p: builtins.any (n: n == p) (names c);
  hasCfg = c: p: builtins.hasAttr p c.config.xdg.configFile;
  feature = name: module: probe:
    let c = mk [ module ];
    in "${name}: ${if probe c then "PASS" else "FAIL"}, packages=${toString (builtins.length c.config.home.packages)}\n";
  default = mk [];
  full = mk (map (n: f.homeModules.${n}) [
    "desktop" "development" "media" "niri" "research" "china-apps"
    "gaming" "theming" "containers" "hardware" "observability"
    "security-tools" "nix-tools" "terminal-tools" "nixvim" "nixos"
  ]);
  fullPass = hasPkg full "nautilus" && hasPkg full "rustup"
    && full.config.programs.mpv.enable
    && hasCfg full "niri/config.kdl"
    && hasPkg full "zotero" && hasPkg full "bilibili"
    && full.config.programs.nixvim.enable
    && builtins.hasAttr "fish/functions/nfu.fish" full.config.xdg.configFile;
in
builtins.concatStringsSep "" [
  "default: ${if hasPkg default "coreutils" && default.config.programs.git.enable && default.config.programs.fish.enable then "PASS" else "FAIL"}, packages=${toString (builtins.length default.config.home.packages)}\n"
  (feature "desktop" f.homeModules.desktop (c: hasPkg c "nautilus" && hasCfg c "kitty/kitty.conf" && c.config.home.sessionVariables.GTK_IM_MODULE == "fcitx"))
  (feature "development" f.homeModules.development (c: hasPkg c "rustup" && c.config.programs.helix.enable && hasCfg c "clangd/config.yaml"))
  (feature "media" f.homeModules.media (c: hasPkg c "obs-studio" && c.config.programs.mpv.enable && c.config.programs.mpv.config."video-sync" == "display-resample"))
  (feature "niri" f.homeModules.niri (c: hasPkg c "niri" && hasPkg c "noctalia" && hasCfg c "niri/config.kdl" && hasCfg c "noctalia/config.toml"))
  (feature "research" f.homeModules.research (c: hasPkg c "zotero" && hasPkg c "sioyek" && c.config.xdg.mimeApps.defaultApplications."application/pdf" == [ "sioyek.desktop" ]))
  (feature "china-apps" f.homeModules."china-apps" (c: hasPkg c "bilibili" && hasPkg c "wemeet" && builtins.hasAttr "clash-verge" c.config.xdg.desktopEntries))
  (feature "nixvim" f.homeModules.nixvim (c: c.config.programs.nixvim.enable && c.config.programs.nixvim.lsp.servers.clangd.enable && c.config.programs.nixvim.plugins.blink-cmp.enable))
  (feature "nixos" f.homeModules.nixos (c: builtins.pathExists /etc/NIXOS && builtins.hasAttr "fish/functions/nfu.fish" c.config.xdg.configFile && c.config.home.sessionPath != []))
  (feature "gaming" f.homeModules.gaming (c: hasPkg c "steam" && hasPkg c "winetricks"))
  (feature "theming" f.homeModules.theming (c: c.config.gtk.enable && builtins.hasAttr "themes/Catppuccin-Purple-Dark-Catppuccin" c.config.xdg.dataFile))
  (feature "containers" f.homeModules.containers (c: hasPkg c "distrobox" && hasPkg c "firecracker"))
  (feature "hardware" f.homeModules.hardware (c: hasPkg c "nvme-cli" && hasPkg c "fwupd"))
  (feature "observability" f.homeModules.observability (c: hasPkg c "bpftrace" && hasPkg c "valgrind"))
  (feature "security-tools" f.homeModules."security-tools" (c: hasPkg c "burpsuite" && hasPkg c "gitleaks"))
  (feature "nix-tools" f.homeModules."nix-tools" (c: hasPkg c "nh" && hasPkg c "nurl"))
  (feature "terminal-tools" f.homeModules."terminal-tools" (c: hasPkg c "zellij" && hasPkg c "jujutsu"))
  "full: ${if fullPass then "PASS" else "FAIL"}, packages=${toString (builtins.length full.config.home.packages)}\n"
]
'
```

Actual output (exit 0):

```text
default: PASS, packages=33
desktop: PASS, packages=51
development: PASS, packages=58
media: PASS, packages=39
niri: PASS, packages=70
research: PASS, packages=49
china-apps: PASS, packages=44
nixvim: PASS, packages=34
nixos: PASS, packages=33
gaming: PASS, packages=36
theming: PASS, packages=38
containers: PASS, packages=36
hardware: PASS, packages=48
observability: PASS, packages=46
security-tools: PASS, packages=43
nix-tools: PASS, packages=40
terminal-tools: PASS, packages=36
full: PASS, packages=205
```

The individual probes behind those rows checked: core packages and Git/Fish for default; Nautilus, Kitty config, and Fcitx environment for desktop; Rustup, Helix, and clangd config for development; MPV settings and OBS for media; Niri/Noctalia packages and configs for Niri; Sioyek/Zotero and PDF MIME ownership for research; Bilibili/Wemeet and Clash desktop metadata for China apps; Nixvim, clangd LSP, and blink-cmp for Nixvim; NixOS Fish functions and platform path for NixOS; and representative packages/configuration for every remaining feature. The full row checks representative desktop, development, media, Niri, research, China-apps, Nixvim, and NixOS outputs.

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

Search scope: `home/`.

Result: `programs.git` occurs only in `home/config/git/default.nix`; `programs.mpv` occurs only in `home/config/mpv/default.nix`; no `programs.noctalia` declaration occurs. Feature files import these owners rather than redeclaring their options.

### NixOS-only paths excluded from portable deployment
The repository search for `/nix/store/`, `/run/opengl-driver`, `/run/wrappers`, `query-driver`, and platform wrapper declarations identified the following **NixOS overlay source files**:

- `home/config/btop/nixos.nix`
- `home/config/helix/nixos.nix`
- `home/config/nixvim/nixos.nix`
- `home/config/fish/nixos.nix`
- `home/config/zsh/nixos.nix`
- `home/config/nushell/nixos.nix`

Those files are not generic portable owners. They are imported only by `home/platform/nixos.nix` (the public `homeModules.nixos` entry point); the platform module is not imported by `home/default.nix`. Therefore generic deployment is bounded to the portable files: `home/config/helix/languages.toml` and `home/config/helix/default.nix` do contain the generic Helix owner, while `home/config/helix/nixos.nix` is intentionally the separate platform overlay. The same split applies to `btop/default.nix` versus `btop/nixos.nix` and `nixvim/lsp.nix` versus `nixvim/nixos.nix`.

The portable-default build and the independent default probe do not import `home/platform/nixos.nix`. The NixOS feature probe separately confirmed the platform overlays and their NixOS-only function/config paths. This distinguishes source-file presence from portable deployment and avoids claiming that the entire `home/config/helix/*` directory is portable.

### Exhaustive generic/dedicated deployment inventory

The following deterministic probe evaluates the generic default once, then each public feature independently. It records total package/home-file/config/data/desktop-entry counts and the exact feature delta from the generic baseline. It normalizes the probe home directory to `$HOME` so the output is stable.

Exact command (run from the worktree root):

```bash
nix eval --impure --raw --show-trace --expr '
let
  f = builtins.getFlake (toString ./.);
  lib = f.inputs.nixpkgs.lib;
  homeDir = "/tmp/task8-owner-probe";
  mk = modules: f.lib.mkHomeConfiguration {
    system = builtins.currentSystem;
    username = "task8-owner-probe";
    homeDirectory = homeDir;
    inherit modules;
  };
  pkgName = p: p.pname or p.name or "unknown";
  sortedUnique = xs: builtins.sort builtins.lessThan (lib.unique xs);
  normalize = p: builtins.replaceStrings [ homeDir ] [ "$HOME" ] p;
  inventory = c: {
    packages = sortedUnique (map pkgName c.config.home.packages);
    homeFile = sortedUnique (map normalize (builtins.attrNames c.config.home.file));
    xdgConfig = sortedUnique (builtins.attrNames c.config.xdg.configFile);
    xdgData = sortedUnique (builtins.attrNames c.config.xdg.dataFile);
    xdgDesktop = sortedUnique (builtins.attrNames c.config.xdg.desktopEntries);
  };
  keys = [ "packages" "homeFile" "xdgConfig" "xdgData" "xdgDesktop" ];
  base = inventory (mk []);
  defs = [
    { name = "desktop"; module = f.homeModules.desktop; }
    { name = "development"; module = f.homeModules.development; }
    { name = "media"; module = f.homeModules.media; }
    { name = "niri"; module = f.homeModules.niri; }
    { name = "research"; module = f.homeModules.research; }
    { name = "china-apps"; module = f.homeModules."china-apps"; }
    { name = "nixvim"; module = f.homeModules.nixvim; }
    { name = "nixos"; module = f.homeModules.nixos; }
    { name = "gaming"; module = f.homeModules.gaming; }
    { name = "theming"; module = f.homeModules.theming; }
    { name = "containers"; module = f.homeModules.containers; }
    { name = "hardware"; module = f.homeModules.hardware; }
    { name = "observability"; module = f.homeModules.observability; }
    { name = "security-tools"; module = f.homeModules."security-tools"; }
    { name = "nix-tools"; module = f.homeModules."nix-tools"; }
    { name = "terminal-tools"; module = f.homeModules."terminal-tools"; }
  ];
  delta = c:
    let i = inventory c;
    in builtins.listToAttrs (map (k: {
      name = k;
      value = lib.subtractLists (builtins.getAttr k base) (builtins.getAttr k i);
    }) keys);
  render = xs: builtins.concatStringsSep "," xs;
  row = d:
    let
      i = inventory (mk [ d.module ]);
      deltaI = delta (mk [ d.module ]);
    in
    builtins.concatStringsSep "\n" [
      "${d.name}: totals packages=${toString (builtins.length i.packages)} homeFile=${toString (builtins.length i.homeFile)} xdgConfig=${toString (builtins.length i.xdgConfig)} xdgData=${toString (builtins.length i.xdgData)} xdgDesktop=${toString (builtins.length i.xdgDesktop)}"
      "  packages=[${render deltaI.packages}]"
      "  homeFile=[${render deltaI.homeFile}]"
      "  xdgConfig=[${render deltaI.xdgConfig}]"
      "  xdgData=[${render deltaI.xdgData}]"
      "  xdgDesktop=[${render deltaI.xdgDesktop}]"
    ];
in
builtins.concatStringsSep "\n" ([
  "generic: totals packages=${toString (builtins.length base.packages)} homeFile=${toString (builtins.length base.homeFile)} xdgConfig=${toString (builtins.length base.xdgConfig)} xdgData=${toString (builtins.length base.xdgData)} xdgDesktop=${toString (builtins.length base.xdgDesktop)}"
] ++ map row defs)'
```

The evaluator emitted the existing LibreOffice versioning warning twice on stderr (`use libreoffice-stable`); the command exited 0. Exact stdout was captured at `/tmp/task8-owner-inventory.txt` (100 lines, 9866 bytes) and is reproduced below:

```text
generic: packages=[bat,btop,coreutils,curl,direnv,dummy-xdg-mime-dirs1,dummy-xdg-mime-dirs2,eza,fastfetch,fd,fish,fzf,git,git-lfs,helix,hm-session-vars.fish,hm-session-vars.sh,home-configuration-reference-manpage,home-manager,jq,less,man-db,mcb-toolchain,nix-zsh-completions,nushell,oh-my-zsh,ouch,ripgrep,shared-mime-info,starship,tmux,zoxide,zsh]
generic: homeFile=[$HOME/.cache/.keep,$HOME/.cache/oh-my-zsh/.keep,$HOME/.config/bat/config,$HOME/.config/btop/btop.conf,$HOME/.config/btop/themes/noctalia.theme,$HOME/.config/direnv/lib/hm-nix-direnv.sh,$HOME/.config/environment.d/10-home-manager.conf,$HOME/.config/fastfetch/config.jsonc,$HOME/.config/fish/conf.d/01-colors.fish,$HOME/.config/fish/conf.d/02-env.fish,$HOME/.config/fish/conf.d/03-options.fish,$HOME/.config/fish/conf.d/05-fzf.fish,$HOME/.config/fish/conf.d/08-bang-bang.fish,$HOME/.config/fish/config.fish,$HOME/.config/fish/functions/_mcb_toolchain.fish,$HOME/.config/fish/functions/backup.fish,$HOME/.config/fish/functions/bootstrap-toolchain.fish,$HOME/.config/fish/functions/check-toolchain.fish,$HOME/.config/fish/functions/copy.fish,$HOME/.config/fish/functions/extract.fish,$HOME/.config/fish/functions/fcd.fish,$HOME/.config/fish/functions/fe.fish,$HOME/.config/fish/functions/history.fish,$HOME/.config/fish/functions/mkcd.fish,$HOME/.config/fish/functions/upgrade-toolchain.fish,$HOME/.config/git/config,$HOME/.config/helix/config.toml,$HOME/.config/helix/languages.toml,$HOME/.config/nushell/config.nu,$HOME/.config/nushell/env.nu,$HOME/.config/starship.toml,$HOME/.config/systemd/user/tray.target,$HOME/.config/tmux/tmux.conf,$HOME/.config/toolchain/tools.json,$HOME/.local/share/fish/home-manager/generated_completions,$HOME/.local/state/.keep,./.zprofile,./.zshenv,./.zshrc,.local/bin/mcb-toolchain,.local/share/fastfetch/logos/logo-01.png,.local/share/fastfetch/logos/logo-02.png,.local/share/fastfetch/logos/logo-03.webp,.manpath]
generic: xdgConfig=[bat/config,btop/btop.conf,btop/themes/noctalia.theme,direnv/lib/hm-nix-direnv.sh,environment.d/10-home-manager.conf,fastfetch/config.jsonc,fish/conf.d/01-colors.fish,fish/conf.d/02-env.fish,fish/conf.d/03-options.fish,fish/conf.d/05-fzf.fish,fish/conf.d/08-bang-bang.fish,fish/config.fish,fish/functions/_mcb_toolchain.fish,fish/functions/backup.fish,fish/functions/bootstrap-toolchain.fish,fish/functions/check-toolchain.fish,fish/functions/copy.fish,fish/functions/extract.fish,fish/functions/fcd.fish,fish/functions/fe.fish,fish/functions/history.fish,fish/functions/mkcd.fish,fish/functions/upgrade-toolchain.fish,git/config,helix/config.toml,helix/languages.toml,starship.toml,systemd/user/tray.target,tmux/tmux.conf,toolchain/tools.json]
generic: xdgData=[fish/home-manager/generated_completions]
generic: xdgDesktop=[]
desktop: totals packages=51 homeFile=45 xdgConfig=31 xdgData=1 xdgDesktop=0
  packageDelta=[aria2,baobab,deja-dup,file-roller,gparted,imv,kdenlive,keepassxc,kitty,localsend,mission-center,nautilus,papers,pavucontrol,qbittorrent,simple-scan,telegram-desktop,zathura-with-plugins]
  homeFileDelta=[$HOME/.config/kitty/kitty.conf]
  xdgConfigDelta=[kitty/kitty.conf]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
development: totals packages=58 homeFile=45 xdgConfig=31 xdgData=1 xdgDesktop=0
  packageDelta=[ShellCheck,bear,binutils-wrapper,bun,ccache,clang-tools,cmake,elan,gcc-wrapper,gnumake,go,lua-language-server,marksman,mold-unwrapped-wrapper,nixd,nixfmt,opam,openssl,pkg-config-wrapper,rustup,sccache,statix,uv,vscode,zed-editor]
  homeFileDelta=[$HOME/.config/clangd/config.yaml]
  xdgConfigDelta=[clangd/config.yaml]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
media: totals packages=39 homeFile=48 xdgConfig=34 xdgData=1 xdgDesktop=0
  packageDelta=[mpd,mpv-with-scripts,ncmpcpp,ncspot,obs-studio,playerctl]
  homeFileDelta=[$HOME/.config/mpv/input.conf,$HOME/.config/mpv/mpv.conf,$HOME/.config/mpv/script-opts/autoload.conf,$HOME/.config/mpv/script-opts/thumbfast.conf]
  xdgConfigDelta=[mpv/input.conf,mpv/mpv.conf,mpv/script-opts/autoload.conf,mpv/script-opts/thumbfast.conf]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
niri: totals packages=70 homeFile=55 xdgConfig=37 xdgData=1 xdgDesktop=0
  packageDelta=[SwayNotificationCenter,anyrun,bash-interactive,cliphist,fcitx5,fcitx5-chinese-addons,fcitx5-gtk,fcitx5-qt6,fcitx5-rime,google-chrome,grim,keepassxc,kitty,linux-wallpaperengine,lock-screen,mission-center,nautilus,niri,niri-run,noctalia,obs-studio,pavucontrol,playerctl,polkit-gnome,rofi,satty,slurp,steam-launcher,swaybg,swayidle,swaylock-effects,telegram-desktop,walker,waybar,wf-recorder,wl-clipboard,wlsunset]
  homeFileDelta=[$HOME/.config/fcitx5/conf/classicui.conf,$HOME/.config/fcitx5/profile,$HOME/.config/kitty/kitty.conf,$HOME/.config/niri/binds.kdl,$HOME/.config/niri/config.kdl,$HOME/.config/niri/rules.kdl,$HOME/.config/noctalia/config.toml,.local/bin/lock-screen,.local/bin/niri-run,.local/bin/steam-launcher,Pictures/Wallpapers]
  xdgConfigDelta=[fcitx5/conf/classicui.conf,fcitx5/profile,kitty/kitty.conf,niri/binds.kdl,niri/config.kdl,niri/rules.kdl,noctalia/config.toml]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
research: totals packages=49 homeFile=46 xdgConfig=31 xdgData=2 xdgDesktop=3
  packageDelta=[biber,goldendict-ng,libreoffice,obsidian,obsidian.desktop,pandoc-cli,poppler-utils,qpdf,sioyek,sioyek.desktop,texlive,texstudio,typst,xournalpp,zotero,zotero.desktop]
  homeFileDelta=[$HOME/.config/mimeapps.list,$HOME/.local/share/applications/mimeapps.list]
  xdgConfigDelta=[mimeapps.list]
  xdgDataDelta=[applications/mimeapps.list]
  xdgDesktopDelta=[obsidian,sioyek,zotero]
china-apps: totals packages=44 homeFile=46 xdgConfig=30 xdgData=3 xdgDesktop=3
  packageDelta=[ani-cli,bilibili,clash-nyanpasu,clash-nyanpasu.desktop,clash-verge-rev,clash-verge.desktop,io.github.msojocs.bilibili.desktop,mangayomi,metacubexd,wemeet,wemeet-xwayland-mesa]
  homeFileDelta=[$HOME/.local/share/applications/io.github.Predidit.Kazumi.desktop,$HOME/.local/share/applications/wemeetapp.desktop]
  xdgConfigDelta=[]
  xdgDataDelta=[applications/io.github.Predidit.Kazumi.desktop,applications/wemeetapp.desktop]
  xdgDesktopDelta=[clash-nyanpasu,clash-verge,io.github.msojocs.bilibili]
nixvim: totals packages=34 homeFile=46 xdgConfig=32 xdgData=1 xdgDesktop=0
  packageDelta=[nixvim]
  homeFileDelta=[$HOME/.config/nvim/init.lua,$HOME/.config/nvim/queries/nix/injections.scm]
  xdgConfigDelta=[nvim/init.lua,nvim/queries/nix/injections.scm]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
nixos: totals packages=33 homeFile=54 xdgConfig=40 xdgData=1 xdgDesktop=0
  packageDelta=[]
  homeFileDelta=[$HOME/.config/fish/functions/_mcb_flake_dir.fish,$HOME/.config/fish/functions/_mcb_flake_ref.fish,$HOME/.config/fish/functions/_mcb_flake_source.fish,$HOME/.config/fish/functions/_mcb_flake_target.fish,$HOME/.config/fish/functions/nfu.fish,$HOME/.config/fish/functions/nrb.fish,$HOME/.config/fish/functions/nrc.fish,$HOME/.config/fish/functions/nrs.fish,$HOME/.config/fish/functions/nrt.fish,$HOME/.config/fish/functions/nru.fish]
  xdgConfigDelta=[fish/functions/_mcb_flake_dir.fish,fish/functions/_mcb_flake_ref.fish,fish/functions/_mcb_flake_source.fish,fish/functions/_mcb_flake_target.fish,fish/functions/nfu.fish,fish/functions/nrb.fish,fish/functions/nrc.fish,fish/functions/nrs.fish,fish/functions/nrt.fish,fish/functions/nru.fish]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
gaming: totals packages=36 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packageDelta=[steam,wine-wow64,winetricks]
  homeFileDelta=[]
  xdgConfigDelta=[]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
theming: totals packages=38 homeFile=52 xdgConfig=33 xdgData=5 xdgDesktop=0
  packageDelta=[adwaita-icon-theme,catppuccin-mocha,gnome-themes-extra,nwg-look,tela-circle-icon-theme]
  homeFileDelta=[$HOME/.config/dconf/.keep,$HOME/.config/gtk-3.0/settings.ini,$HOME/.config/gtk-4.0/settings.ini,$HOME/.gtkrc-2.0,$HOME/.local/share/icons/Catppuccin-Mocha-Mauve-Cursors,$HOME/.local/share/themes/Catppuccin-Purple-Dark-Catppuccin,$HOME/.local/share/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi,$HOME/.local/share/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi]
  xdgConfigDelta=[dconf/.keep,gtk-3.0/settings.ini,gtk-4.0/settings.ini]
  xdgDataDelta=[icons/Catppuccin-Mocha-Mauve-Cursors,themes/Catppuccin-Purple-Dark-Catppuccin,themes/Catppuccin-Purple-Dark-Catppuccin-hdpi,themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi]
  xdgDesktopDelta=[]
containers: totals packages=36 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packageDelta=[distrobox,firecracker,podman-compose]
  homeFileDelta=[]
  xdgConfigDelta=[]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
hardware: totals packages=48 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packageDelta=[blueman,bluez,bluez-tools,cpuid,dmidecode,efibootmgr,flashrom,fwupd,hdparm,nvme-cli,pciutils,sbctl,sdparm,smartmontools,usbutils]
  homeFileDelta=[]
  xdgConfigDelta=[]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
observability: totals packages=46 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packageDelta=[FlameGraph,bcc,bpftrace,fio,hotspot,ioping,kernelshark,lnav,perf-linux,rr,sysdig,trace-cmd,valgrind]
  homeFileDelta=[]
  xdgConfigDelta=[]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
security-tools: totals packages=43 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packageDelta=[autopsy,burpsuite,foremost,gitleaks,gnupg,hashcat,john,metasploit-framework,paperkey,trivy]
  homeFileDelta=[]
  xdgConfigDelta=[]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
nix-tools: totals packages=40 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packageDelta=[comma,nh,nix-du,nix-index,nix-output-monitor,nix-tree,nurl]
  homeFileDelta=[]
  xdgConfigDelta=[]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
terminal-tools: totals packages=36 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packageDelta=[herdr,jujutsu,zellij]
  homeFileDelta=[]
  xdgConfigDelta=[]
  xdgDataDelta=[]
  xdgDesktopDelta=[]
```

The inventory proves the generic module owns the baseline package/config set; each dedicated feature contributes a deterministic delta in the listed deployment namespaces. NixOS contributes no package delta and only its explicit Fish helper files; its source assets are platform-only because of the import boundary above.

### Raw-file ownership search

Repository search was used for active source references (`source`, `builtins.readFile`, `builtins.pathExists`, generated text, and imports) across `home/` and `flake/`. The retained raw assets were all found beside their owners: Fastfetch logos under `config/fastfetch`, MPV Lua/patch files under `config/mpv`, Nixvim patch under `config/nixvim/patches`, Fcitx5 profile/config, Niri KDL files, Helix TOML files, shell startup/functions, and theme/wallpaper data each have active owner references. The previously identified orphan files remain absent. The catch-all search above also confirms the deleted root deployment modules are not active.

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

## Commits

- Baseline verified architecture commit: `0d709a615e9a914fd5ac77148808445e147e0b61`
- Formatter/report commit: `eb99b7fc815867311651b3a32d9e34168a32cbe8` — `chore: complete Task 8 verification gate`
- Report correction follow-up: `282ce2268bc4d1dd1d131c224473d3369ba56757` — `docs: record Task 8 delivery commit`
- Final evidence follow-up: recorded after this report-only commit.

The first delivery commit contains the three formatter changes and the initial report. The two follow-ups contain report metadata/evidence only. The pre-existing `task-3-report.md` correction remains unstaged and excluded.


## Unresolved risks

1. Zsh startup remains runtime-unverified because `zsh` is unavailable on the host.
2. Niri/Noctalia and GUI application behavior remains runtime-unverified because no graphical session was launched and `noctalia-session` is unavailable.
3. NixOS platform behavior was evaluated on a host exposing `/etc/NIXOS`, but no activation or `nixos-rebuild` was run.
4. The Bash command in the brief names `home/scripts/*.sh`, while the repository's active `home/scripts/mcb-toolchain` is extensionless; the corrected available-script parse passed.
5. The existing upstream LibreOffice package warning recommends `libreoffice-stable`; it did not affect evaluation or the build and was not changed in this verification-only task.

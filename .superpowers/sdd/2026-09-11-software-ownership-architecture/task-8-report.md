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
`lib.subtractLists` in nixpkgs removes the first list from the second list, so `lib.subtractLists base i` is intentionally the feature-minus-baseline delta. An independent semantics probe returned `{"baseThenFeature":["feature"],"featureThenBase":["base"]}` for `lib.subtractLists ["base"] ["feature"]` and its reversed operands. The reviewer suggestion to reverse these operands would therefore produce baseline-only entries, not feature additions.

The evaluator emitted the existing LibreOffice versioning warning twice on stderr (`use libreoffice-stable`); the command exited 0. Exact stdout was captured at `/tmp/task8-owner-inventory.txt` (96 lines, 6798 bytes; SHA-256 `47d1f6e85b7f51a6cb8de339e6c18c63ae9f5df03ef46f730e53db5b2c7a9775`) and is reproduced below:

```text
generic: totals packages=33 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
desktop: totals packages=51 homeFile=45 xdgConfig=31 xdgData=1 xdgDesktop=0
  packages=[aria2,baobab,deja-dup,file-roller,gparted,imv,kdenlive,keepassxc,kitty,localsend,mission-center,nautilus,papers,pavucontrol,qbittorrent,simple-scan,telegram-desktop,zathura-with-plugins]
  homeFile=[$HOME/.config/kitty/kitty.conf]
  xdgConfig=[kitty/kitty.conf]
  xdgData=[]
  xdgDesktop=[]
development: totals packages=58 homeFile=45 xdgConfig=31 xdgData=1 xdgDesktop=0
  packages=[ShellCheck,bear,binutils-wrapper,bun,ccache,clang-tools,cmake,elan,gcc-wrapper,gnumake,go,lua-language-server,marksman,mold-unwrapped-wrapper,nixd,nixfmt,opam,openssl,pkg-config-wrapper,rustup,sccache,statix,uv,vscode,zed-editor]
  homeFile=[$HOME/.config/clangd/config.yaml]
  xdgConfig=[clangd/config.yaml]
  xdgData=[]
  xdgDesktop=[]
media: totals packages=39 homeFile=48 xdgConfig=34 xdgData=1 xdgDesktop=0
  packages=[mpd,mpv-with-scripts,ncmpcpp,ncspot,obs-studio,playerctl]
  homeFile=[$HOME/.config/mpv/input.conf,$HOME/.config/mpv/mpv.conf,$HOME/.config/mpv/script-opts/autoload.conf,$HOME/.config/mpv/script-opts/thumbfast.conf]
  xdgConfig=[mpv/input.conf,mpv/mpv.conf,mpv/script-opts/autoload.conf,mpv/script-opts/thumbfast.conf]
  xdgData=[]
  xdgDesktop=[]
niri: totals packages=70 homeFile=55 xdgConfig=37 xdgData=1 xdgDesktop=0
  packages=[SwayNotificationCenter,anyrun,bash-interactive,cliphist,fcitx5,fcitx5-chinese-addons,fcitx5-gtk,fcitx5-qt6,fcitx5-rime,google-chrome,grim,keepassxc,kitty,linux-wallpaperengine,lock-screen,mission-center,nautilus,niri,niri-run,noctalia,obs-studio,pavucontrol,playerctl,polkit-gnome,rofi,satty,slurp,steam-launcher,swaybg,swayidle,swaylock-effects,telegram-desktop,walker,waybar,wf-recorder,wl-clipboard,wlsunset]
  homeFile=[$HOME/.config/fcitx5/conf/classicui.conf,$HOME/.config/fcitx5/profile,$HOME/.config/kitty/kitty.conf,$HOME/.config/niri/binds.kdl,$HOME/.config/niri/config.kdl,$HOME/.config/niri/rules.kdl,$HOME/.config/noctalia/config.toml,.local/bin/lock-screen,.local/bin/niri-run,.local/bin/steam-launcher,Pictures/Wallpapers]
  xdgConfig=[fcitx5/conf/classicui.conf,fcitx5/profile,kitty/kitty.conf,niri/binds.kdl,niri/config.kdl,niri/rules.kdl,noctalia/config.toml]
  xdgData=[]
  xdgDesktop=[]
research: totals packages=49 homeFile=46 xdgConfig=31 xdgData=2 xdgDesktop=3
  packages=[biber,goldendict-ng,libreoffice,obsidian,obsidian.desktop,pandoc-cli,poppler-utils,qpdf,sioyek,sioyek.desktop,texlive,texstudio,typst,xournalpp,zotero,zotero.desktop]
  homeFile=[$HOME/.config/mimeapps.list,$HOME/.local/share/applications/mimeapps.list]
  xdgConfig=[mimeapps.list]
  xdgData=[applications/mimeapps.list]
  xdgDesktop=[obsidian,sioyek,zotero]
china-apps: totals packages=44 homeFile=46 xdgConfig=30 xdgData=3 xdgDesktop=3
  packages=[ani-cli,bilibili,clash-nyanpasu,clash-nyanpasu.desktop,clash-verge-rev,clash-verge.desktop,io.github.msojocs.bilibili.desktop,mangayomi,metacubexd,wemeet,wemeet-xwayland-mesa]
  homeFile=[$HOME/.local/share/applications/io.github.Predidit.Kazumi.desktop,$HOME/.local/share/applications/wemeetapp.desktop]
  xdgConfig=[]
  xdgData=[applications/io.github.Predidit.Kazumi.desktop,applications/wemeetapp.desktop]
  xdgDesktop=[clash-nyanpasu,clash-verge,io.github.msojocs.bilibili]
nixvim: totals packages=34 homeFile=46 xdgConfig=32 xdgData=1 xdgDesktop=0
  packages=[nixvim]
  homeFile=[$HOME/.config/nvim/init.lua,$HOME/.config/nvim/queries/nix/injections.scm]
  xdgConfig=[nvim/init.lua,nvim/queries/nix/injections.scm]
  xdgData=[]
  xdgDesktop=[]
nixos: totals packages=33 homeFile=54 xdgConfig=40 xdgData=1 xdgDesktop=0
  packages=[]
  homeFile=[$HOME/.config/fish/functions/_mcb_flake_dir.fish,$HOME/.config/fish/functions/_mcb_flake_ref.fish,$HOME/.config/fish/functions/_mcb_flake_source.fish,$HOME/.config/fish/functions/_mcb_flake_target.fish,$HOME/.config/fish/functions/nfu.fish,$HOME/.config/fish/functions/nrb.fish,$HOME/.config/fish/functions/nrc.fish,$HOME/.config/fish/functions/nrs.fish,$HOME/.config/fish/functions/nrt.fish,$HOME/.config/fish/functions/nru.fish]
  xdgConfig=[fish/functions/_mcb_flake_dir.fish,fish/functions/_mcb_flake_ref.fish,fish/functions/_mcb_flake_source.fish,fish/functions/_mcb_flake_target.fish,fish/functions/nfu.fish,fish/functions/nrb.fish,fish/functions/nrc.fish,fish/functions/nrs.fish,fish/functions/nrt.fish,fish/functions/nru.fish]
  xdgData=[]
  xdgDesktop=[]
gaming: totals packages=36 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packages=[steam,wine-wow64,winetricks]
  homeFile=[]
  xdgConfig=[]
  xdgData=[]
  xdgDesktop=[]
theming: totals packages=38 homeFile=52 xdgConfig=33 xdgData=5 xdgDesktop=0
  packages=[adwaita-icon-theme,catppuccin-mocha,gnome-themes-extra,nwg-look,tela-circle-icon-theme]
  homeFile=[$HOME/.config/dconf/.keep,$HOME/.config/gtk-3.0/settings.ini,$HOME/.config/gtk-4.0/settings.ini,$HOME/.gtkrc-2.0,$HOME/.local/share/icons/Catppuccin-Mocha-Mauve-Cursors,$HOME/.local/share/themes/Catppuccin-Purple-Dark-Catppuccin,$HOME/.local/share/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi,$HOME/.local/share/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi]
  xdgConfig=[dconf/.keep,gtk-3.0/settings.ini,gtk-4.0/settings.ini]
  xdgData=[icons/Catppuccin-Mocha-Mauve-Cursors,themes/Catppuccin-Purple-Dark-Catppuccin,themes/Catppuccin-Purple-Dark-Catppuccin-hdpi,themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi]
  xdgDesktop=[]
containers: totals packages=36 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packages=[distrobox,firecracker,podman-compose]
  homeFile=[]
  xdgConfig=[]
  xdgData=[]
  xdgDesktop=[]
hardware: totals packages=48 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packages=[blueman,bluez,bluez-tools,cpuid,dmidecode,efibootmgr,flashrom,fwupd,hdparm,nvme-cli,pciutils,sbctl,sdparm,smartmontools,usbutils]
  homeFile=[]
  xdgConfig=[]
  xdgData=[]
  xdgDesktop=[]
observability: totals packages=46 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packages=[FlameGraph,bcc,bpftrace,fio,hotspot,ioping,kernelshark,lnav,perf-linux,rr,sysdig,trace-cmd,valgrind]
  homeFile=[]
  xdgConfig=[]
  xdgData=[]
  xdgDesktop=[]
security-tools: totals packages=43 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packages=[autopsy,burpsuite,foremost,gitleaks,gnupg,hashcat,john,metasploit-framework,paperkey,trivy]
  homeFile=[]
  xdgConfig=[]
  xdgData=[]
  xdgDesktop=[]
nix-tools: totals packages=40 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packages=[comma,nh,nix-du,nix-index,nix-output-monitor,nix-tree,nurl]
  homeFile=[]
  xdgConfig=[]
  xdgData=[]
  xdgDesktop=[]
terminal-tools: totals packages=36 homeFile=44 xdgConfig=30 xdgData=1 xdgDesktop=0
  packages=[herdr,jujutsu,zellij]
  homeFile=[]
  xdgConfig=[]
  xdgData=[]
  xdgDesktop=[]
```

The inventory proves the generic module owns the baseline package/config set; each dedicated feature contributes a deterministic delta in the listed deployment namespaces. NixOS contributes no package delta and only its explicit Fish helper files; its source assets are platform-only because of the import boundary above.

### Raw-file ownership search

Repository search was used for active source references (`source`, `builtins.readFile`, `builtins.pathExists`, generated text, and imports) across `home/` and `flake/`. The retained raw assets were all found beside their owners: Fastfetch logos under `config/fastfetch`, MPV Lua/patch files under `config/mpv`, Nixvim patch under `config/nixvim/patches`, Fcitx5 profile/config, Niri KDL files, Helix TOML files, shell startup/functions, and theme/wallpaper data each have active owner references. The previously identified orphan files remain absent. The catch-all search above also confirms the deleted root deployment modules are not active.

### Raw-file ownership probe

The following executable Nix probe recursively enumerates every regular file under `home/config`, `home/assets`, and `home/scripts`, excludes only Nix module files, maps each retained raw file to its dedicated owner, checks that both paths exist, and checks the owner source text contains the expected source/read/import marker. An unmapped file or missing marker throws; every emitted record must be `PASS`.

Exact command (run from the worktree root):

```bash
nix eval --impure --raw --show-trace --expr '
let
  f = builtins.getFlake (toString ./.);
  lib = f.inputs.nixpkgs.lib;
  root = ./.;
  walk = dir: prefix:
    let entries = builtins.readDir dir;
    in lib.concatLists (map (name:
      let
        kind = entries.${name};
        path = dir + "/${name}";
        rel = "${prefix}/${name}";
      in
      if kind == "directory" then
        walk path rel
      else if kind == "regular" then
        [ { inherit path rel; } ]
      else
        [ ]
    ) (builtins.attrNames entries));
  allFiles = lib.concatLists [
    (walk (root + "/home/config") "home/config")
    (walk (root + "/home/assets") "home/assets")
    (walk (root + "/home/scripts") "home/scripts")
  ];
  rawFiles = builtins.filter (file: !(lib.hasSuffix ".nix" file.rel)) allFiles;
  basename = rel: builtins.elemAt (lib.splitString "/" rel) ((builtins.length (lib.splitString "/" rel)) - 1);
  nixosFishFunctions = [ "_mcb_flake_dir" "_mcb_flake_ref" "_mcb_flake_source" "_mcb_flake_target" "nfu" "nrb" "nrc" "nrs" "nrt" "nru" ];
  owner = rel:
    if lib.hasPrefix "home/assets/themes/" rel then {
      path = "home/features/theming.nix";
      marker = "../assets/themes/";
      relation = "recursive theme directory";
    } else if lib.hasPrefix "home/assets/wallpapers/" rel then {
      path = "home/config/noctalia/default.nix";
      marker = "../../assets/wallpapers";
      relation = "recursive wallpaper directory";
    } else if rel == "home/scripts/mcb-toolchain" then {
      path = "home/scripts/default.nix";
      marker = "./mcb-toolchain";
      relation = "builtins.readFile source";
    } else if lib.hasPrefix "home/config/niri/" rel then {
      path = "home/config/niri/default.nix";
      marker = "./${basename rel}";
      relation = "direct source";
    } else if lib.hasPrefix "home/config/helix/" rel then
      if basename rel == "nixos.toml" then {
        path = "home/config/helix/nixos.nix";
        marker = "./nixos.toml";
        relation = "platform readFile source";
      } else {
        path = "home/config/helix/default.nix";
        marker = "./${basename rel}";
        relation = "direct source";
      }
    else if lib.hasPrefix "home/config/fcitx5/" rel then {
      path = "home/config/fcitx5/default.nix";
      marker = "./${if basename rel == "classicui.conf" then "conf/classicui.conf" else basename rel}";
      relation = "direct source";
    } else if lib.hasPrefix "home/config/btop/themes/" rel then {
      path = "home/config/btop/default.nix";
      marker = "./themes/${basename rel}";
      relation = "direct source";
    } else if lib.hasPrefix "home/config/btop/" rel then {
      path = "home/config/btop/default.nix";
      marker = "./${basename rel}";
      relation = "direct source";
    } else if lib.hasPrefix "home/config/fastfetch/assets/" rel then {
      path = "home/config/fastfetch/default.nix";
      marker = "./assets/fastfetch-logos/${basename rel}";
      relation = "direct source";
    } else if rel == "home/config/fastfetch/mokka.jsonc" then {
      path = "home/config/fastfetch/default.nix";
      marker = "./mokka.jsonc";
      relation = "direct source";
    } else if lib.hasPrefix "home/config/starship/" rel then {
      path = "home/config/starship/default.nix";
      marker = "./starship.toml";
      relation = "direct source";
    } else if lib.hasPrefix "home/config/nixvim/patches/" rel then {
      path = "home/config/nixvim/plugins.nix";
      marker = "./patches/${basename rel}";
      relation = "postPatch readFile source";
    } else if lib.hasPrefix "home/config/nushell/" rel then
      if basename rel == "nixos.nu" then {
        path = "home/config/nushell/nixos.nix";
        marker = "./nixos.nu";
        relation = "platform readFile source";
      } else {
        path = "home/config/nushell/default.nix";
        marker = "./${basename rel}";
        relation = "direct source";
      }
    else if lib.hasPrefix "home/config/zsh/" rel then
      if basename rel == "nixos.zsh" then {
        path = "home/config/zsh/nixos.nix";
        marker = "./nixos.zsh";
        relation = "platform readFile source";
      } else {
        path = "home/config/zsh/default.nix";
        marker = "./.zshrc";
        relation = "direct readFile source";
      }
    else if rel == "home/config/fish/config.fish" then {
      path = "home/config/fish/default.nix";
      marker = "./config.fish";
      relation = "direct readFile source";
    } else if lib.hasPrefix "home/config/fish/conf.d/" rel then {
      path = "home/config/fish/default.nix";
      marker = "./conf.d";
      relation = "readDir/source mapping";
    } else if lib.hasPrefix "home/config/fish/functions/" rel then
      if builtins.elem (basename rel) (map (name: "${name}.fish") nixosFishFunctions) then {
        path = "home/config/fish/nixos.nix";
        marker = "./functions";
        relation = "platform function mapping";
      } else {
        path = "home/config/fish/default.nix";
        marker = "./functions";
        relation = "portable function mapping";
      }
    else if rel == "home/config/clangd/config.yaml" then {
      path = "home/config/clangd/default.nix";
      marker = "./config.yaml";
      relation = "direct source";
    } else if rel == "home/config/kitty/kitty.conf" then {
      path = "home/config/kitty/default.nix";
      marker = "./kitty.conf";
      relation = "direct source";
    } else if rel == "home/config/toolchain/tools.json" then {
      path = "home/config/toolchain/default.nix";
      marker = "./tools.json";
      relation = "direct source";
    } else if rel == "home/config/mpv/hold_forward.lua" then {
      path = "home/config/mpv/default.nix";
      marker = "./hold_forward.lua";
      relation = "readFile source";
    } else if lib.hasPrefix "home/config/mpv/patches/" rel then {
      path = "home/config/mpv/default.nix";
      marker = "./patches/${basename rel}";
      relation = "postPatch readFile source";
    } else if rel == "home/config/tmux/tmux.conf" then {
      path = "home/config/tmux/default.nix";
      marker = "./tmux.conf";
      relation = "readFile source";
    } else
      throw "unmapped retained raw file: ${rel}";
  checked = map (file:
    let
      o = owner file.rel;
      ownerPath = root + "/${o.path}";
      ownerText = builtins.readFile ownerPath;
      markerOk = lib.hasInfix o.marker ownerText;
      pathOk = builtins.pathExists file.path && builtins.pathExists ownerPath;
    in {
      inherit (file) rel;
      owner = o.path;
      relation = o.relation;
      ok = pathOk && markerOk;
    }
  ) rawFiles;
  render = item: "${if item.ok then "PASS" else "FAIL"} ${item.rel} -> ${item.owner} (${item.relation})";
in if builtins.all (item: item.ok) checked then builtins.concatStringsSep "\n" (map render checked) else throw "raw ownership probe failed"' > /tmp/task8-raw-ownership-final.txt
status=$?
printf 'raw-probe-exit=%s\n' "$status"
if [ "$status" -eq 0 ]; then
  wc -l -c /tmp/task8-raw-ownership-final.txt
  sha256sum /tmp/task8-raw-ownership-final.txt
fi
exit "$status"
```

Result: **exit 0**; the probe emitted 731 per-file records, with no `FAIL` lines. The exact stdout was captured at `/tmp/task8-raw-ownership-final.txt` (730 newline-terminated lines, 105532 bytes; SHA-256 `0f113d256004f0ec5539eb8ff97e764d2479a29365bf59fe94997f043fdf04e1`) and is reproduced below.

```text
PASS home/config/btop/btop.conf -> home/config/btop/default.nix (direct source)
PASS home/config/btop/themes/noctalia.theme -> home/config/btop/default.nix (direct source)
PASS home/config/clangd/config.yaml -> home/config/clangd/default.nix (direct source)
PASS home/config/fastfetch/assets/fastfetch-logos/logo-01.png -> home/config/fastfetch/default.nix (direct source)
PASS home/config/fastfetch/assets/fastfetch-logos/logo-02.png -> home/config/fastfetch/default.nix (direct source)
PASS home/config/fastfetch/assets/fastfetch-logos/logo-03.webp -> home/config/fastfetch/default.nix (direct source)
PASS home/config/fastfetch/mokka.jsonc -> home/config/fastfetch/default.nix (direct source)
PASS home/config/fcitx5/conf/classicui.conf -> home/config/fcitx5/default.nix (direct source)
PASS home/config/fcitx5/profile -> home/config/fcitx5/default.nix (direct source)
PASS home/config/fish/conf.d/01-colors.fish -> home/config/fish/default.nix (readDir/source mapping)
PASS home/config/fish/conf.d/02-env.fish -> home/config/fish/default.nix (readDir/source mapping)
PASS home/config/fish/conf.d/03-options.fish -> home/config/fish/default.nix (readDir/source mapping)
PASS home/config/fish/conf.d/05-fzf.fish -> home/config/fish/default.nix (readDir/source mapping)
PASS home/config/fish/conf.d/08-bang-bang.fish -> home/config/fish/default.nix (readDir/source mapping)
PASS home/config/fish/config.fish -> home/config/fish/default.nix (direct readFile source)
PASS home/config/fish/functions/_mcb_flake_dir.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/_mcb_flake_ref.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/_mcb_flake_source.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/_mcb_flake_target.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/_mcb_toolchain.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/backup.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/bootstrap-toolchain.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/check-toolchain.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/copy.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/extract.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/fcd.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/fe.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/history.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/mkcd.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/fish/functions/nfu.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/nrb.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/nrc.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/nrs.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/nrt.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/nru.fish -> home/config/fish/nixos.nix (platform function mapping)
PASS home/config/fish/functions/upgrade-toolchain.fish -> home/config/fish/default.nix (portable function mapping)
PASS home/config/helix/config.toml -> home/config/helix/default.nix (direct source)
PASS home/config/helix/languages.toml -> home/config/helix/default.nix (direct source)
PASS home/config/helix/nixos.toml -> home/config/helix/nixos.nix (platform readFile source)
PASS home/config/kitty/kitty.conf -> home/config/kitty/default.nix (direct source)
PASS home/config/mpv/hold_forward.lua -> home/config/mpv/default.nix (readFile source)
PASS home/config/mpv/patches/secure-uosc-post-patch.sh -> home/config/mpv/default.nix (postPatch readFile source)
PASS home/config/niri/binds.kdl -> home/config/niri/default.nix (direct source)
PASS home/config/niri/config.kdl -> home/config/niri/default.nix (direct source)
PASS home/config/niri/outputs.kdl -> home/config/niri/default.nix (direct source)
PASS home/config/niri/rules.kdl -> home/config/niri/default.nix (direct source)
PASS home/config/nixvim/patches/markdown-preview-bun-post-patch.sh -> home/config/nixvim/plugins.nix (postPatch readFile source)
PASS home/config/nushell/config.nu -> home/config/nushell/default.nix (direct source)
PASS home/config/nushell/env.nu -> home/config/nushell/default.nix (direct source)
PASS home/config/nushell/nixos.nu -> home/config/nushell/nixos.nix (platform readFile source)
PASS home/config/starship/starship.toml -> home/config/starship/default.nix (direct source)
PASS home/config/tmux/tmux.conf -> home/config/tmux/default.nix (readFile source)
PASS home/config/toolchain/tools.json -> home/config/toolchain/default.nix (direct source)
PASS home/config/zsh/.zshrc -> home/config/zsh/default.nix (direct readFile source)
PASS home/config/zsh/nixos.zsh -> home/config/zsh/nixos.nix (platform readFile source)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/00000000000000020006000e7e9ffc3f -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/00008160000006810000408080010102 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/03b6e0fcb3499374a867c041f52298f0 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/08e8e1c95fe2fc01f976f1e063a24ccd -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/1081e37283d90000800003c07f3ef6bf -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/3085a0e285430894940527032f8b26df -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/3ecb610c1bf2410f44200f48c40d3599 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/4498f0e0c1937ffe01fd06f973665830 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/5c6cd98b3f3ebcb1f9c7f1c204630408 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/6407b0e94181790501fd1e167b474872 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/640fb0e74195791501fd1ed57b41487f -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/9081237383d90e509aa00f00170e968f -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/9d800788f1b08800ae810202380a0822 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/X_cursor -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/a2a266d0498c3104214a47bd64ab0fc8 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/alias -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/all-scroll -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/b66166c04f8c3109214a4fbd64a50fc8 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/bottom_left_corner -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/bottom_right_corner -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/bottom_side -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/cell -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/center_ptr -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/circle -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/closedhand -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/col-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/color-picker -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/context-menu -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/copy -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/cross -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/crossed_circle -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/crosshair -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/d9ce0ab605698f320427677b458ad60b -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/default -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/dnd-copy -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/dnd-move -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/dnd-no-drop -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/dnd-none -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/down-arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/draft -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/e-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/e29285e634086352946a0e7090d73106 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/ew-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/fcf21c00b30f7e3f83fe0dfd12e71cff -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/fleur -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/forbidden -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/grab -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/grabbing -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/h_double_arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/half-busy -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/hand -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/hand1 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/hand2 -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/help -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/ibeam -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/left-arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/left_ptr -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/left_ptr_help -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/left_ptr_watch -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/left_side -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/link -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/ll_angle -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/lr_angle -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/move -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/n-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/ne-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/nesw-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/no-drop -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/not-allowed -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/ns-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/nw-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/nwse-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/openhand -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/pencil -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/pirate -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/plus -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/pointer -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/pointing_hand -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/progress -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/question_arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/right-arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/right_ptr -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/right_side -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/row-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/s-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/sb_h_double_arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/sb_v_double_arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/se-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size-bdiag -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size-fdiag -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size-hor -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size-ver -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size_all -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size_bdiag -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size_fdiag -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size_hor -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/size_ver -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/split_h -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/split_v -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/sw-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/text -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/top_left_arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/top_left_corner -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/top_right_corner -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/top_side -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/ul_angle -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/up-arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/ur_angle -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/v_double_arrow -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/vertical-text -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/w-resize -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/wait -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/watch -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/wayland-cursor -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/whats_this -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/x-cursor -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/xterm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/zoom-in -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/cursors/zoom-out -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Mocha-Mauve-Cursors/index.theme -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/add-workspace-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/add-workspace-hover.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/add-workspace.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/calendar-arrow-left.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/calendar-arrow-right.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/checkbox-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/checkbox-off.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/checkbox.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/close-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/close-hover.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/close.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/corner-ripple.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/radiobutton-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/radiobutton-off.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/radiobutton.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/toggle-off.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/toggle-on-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/toggle-on.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/assets/trash-icon.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/cinnamon.css -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/cinnamon/thumbnail.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/calendar-arrow-left.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/calendar-arrow-right.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/calendar-today.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/checkbox-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/checkbox-off-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/checkbox-off-hover.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/checkbox-off.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/checkbox.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/dash-placeholder.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/noise-texture.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/process-working.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/toggle-off.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/toggle-on-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/assets/toggle-on.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/gnome-shell.css -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gnome-shell/pad-osd.css -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/apps.rc -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/border.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/button-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/button-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/button-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/button.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-checked-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-checked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-checked-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-checked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-mixed-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-mixed-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-mixed-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-mixed.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-unchecked-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-unchecked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-unchecked-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/checkbox-unchecked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-left-entry-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-left-entry-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-left-entry-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-left-entry.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-right-entry-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-right-entry-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-right-entry-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/combo-right-entry.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/entry-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/entry-background-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/entry-background.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/entry-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/entry-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/entry.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/flat-button-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/flat-button-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/flat-button-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/flat-button.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/focus.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/frame-inline.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/frame-notebook.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/frame.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/handle-horz-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/handle-horz-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/handle-horz.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/handle-vert-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/handle-vert-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/handle-vert.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-checkbox-checked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-checkbox-checked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-checkbox-mixed-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-checkbox-mixed.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-checkbox-unchecked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-checkbox-unchecked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-radio-checked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-radio-checked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-radio-mixed-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-radio-mixed.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-radio-unchecked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/menu-radio-unchecked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-down-alt-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-down-alt.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-down-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-down.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-left-alt-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-left-alt.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-left-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-left-semi.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-left.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-right-alt-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-right-alt.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-right-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-right-semi.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-right.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-up-alt-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-up-alt.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-up-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/pan-up.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/progressbar-progress.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/progressbar-trough.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-checked-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-checked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-checked-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-checked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-mixed-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-mixed-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-mixed-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-mixed.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-unchecked-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-unchecked-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-unchecked-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/radio-unchecked.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-horz-trough-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-horz-trough-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-horz-trough.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-slider-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-slider-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-slider-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-slider.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-vert-trough-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-vert-trough-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scale-vert-trough.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-horz-slider-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-horz-slider-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-horz-slider-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-horz-slider.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-horz-trough.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-ltr-slider-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-ltr-slider-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-ltr-slider-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-ltr-slider.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-ltr-trough.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-rtl-slider-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-rtl-slider-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-rtl-slider-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-rtl-slider.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/scrollbar-vert-rtl-trough.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-down-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-down-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-down-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-down.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-up-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-up-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-up-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-ltr-up.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-down-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-down-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-down-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-down.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-up-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-up-disabled.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-up-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/spin-rtl-up.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/tab.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/treeview-ltr-button-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/treeview-ltr-button-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/treeview-ltr-button.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/treeview-rtl-button-active.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/treeview-rtl-button-hover.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/assets/treeview-rtl-button.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/gtkrc -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/hacks.rc -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-2.0/main.rc -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/checkbox-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/checkbox-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/checkbox-mixed-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/checkbox-mixed-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/close-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/close-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/cursor-handle-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/maximize-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/maximize-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/menu-radio-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/menu-radio-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/minimize-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/minimize-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/radio-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/radio-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-after-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-horz-marks-before-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-after-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/scale-vert-marks-before-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-checked-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-checked-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-checked.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-checked@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-unchecked-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-unchecked-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-unchecked.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/selectionmode-checkbox-unchecked@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/small-checkbox-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/small-checkbox-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/small-checkbox-mixed-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/small-checkbox-mixed-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/small-radio-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/small-radio-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/unmaximize-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/assets/unmaximize-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/gtk-dark.css -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/gtk.css -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-3.0/thumbnail.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/checkbox-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/checkbox-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/checkbox-mixed-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/checkbox-mixed-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/close-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/close-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/cursor-handle-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/maximize-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/maximize-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/menu-radio-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/menu-radio-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/minimize-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/minimize-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/radio-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/radio-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-after-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-horz-marks-before-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-after-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider-disabled-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider-disabled-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider-disabled.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider-disabled@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/scale-vert-marks-before-slider@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-checked-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-checked-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-checked.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-checked@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-unchecked-dark.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-unchecked-dark@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-unchecked.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/selectionmode-checkbox-unchecked@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/small-checkbox-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/small-checkbox-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/small-checkbox-mixed-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/small-checkbox-mixed-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/small-radio-checked-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/small-radio-checked-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/unmaximize-symbolic.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/assets/unmaximize-symbolic@2.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/gtk-dark.css -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/gtk.css -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/gtk-4.0/thumbnail.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/index.theme -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/button.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/close.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/maximize.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/menu.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/minimize.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/shade.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/unmaximize.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/assets/unshade.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/metacity-theme-3.xml -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/metacity-1/thumbnail.png -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/plank/dock.theme -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-right-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/bottom-right-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/button-active-Normal.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/button-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/button-inactive-Normal.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/button-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/close-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/close-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/close-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/close-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/hide-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/hide-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/hide-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/hide-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/maximize-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/menu-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/menu-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/menu-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/menu-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/shade-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/stick-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/themerc -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/title-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/title-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/title-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/title-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-right-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin/xfwm4/top-right-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-right-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/bottom-right-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/button-active-Normal.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/button-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/button-inactive-Normal.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/button-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/close-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/close-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/close-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/close-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/hide-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/hide-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/hide-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/hide-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/maximize-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/menu-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/menu-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/menu-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/menu-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/shade-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/stick-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/themerc -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/title-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/title-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/title-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/title-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-right-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-hdpi/xfwm4/top-right-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-right-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/bottom-right-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/button-active-Normal.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/button-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/button-inactive-Normal.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/button-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/close-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/close-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/close-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/close-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/hide-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/hide-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/hide-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/hide-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/maximize-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/menu-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/menu-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/menu-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/menu-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/shade-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-toggled-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-toggled-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-toggled-prelight.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/stick-toggled-pressed.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/themerc -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/title-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/title-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/title-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/title-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-left-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-left-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-left-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-left-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-right-active.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-right-active.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-right-inactive.svg -> home/features/theming.nix (recursive theme directory)
PASS home/assets/themes/Catppuccin-Purple-Dark-Catppuccin-xhdpi/xfwm4/top-right-inactive.xpm -> home/features/theming.nix (recursive theme directory)
PASS home/assets/wallpapers/Abstract.jpg -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Circuit.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Dragon.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Garuda Broadwing.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Garuda Desert.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Patak Remix.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Raptor TilliDie SGS.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Raptor jpg.jpg -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Raptor.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/River-city-Mocha-Blurred.jpg -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Shani.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/Stripes.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/file_0000000011a871fdae91f3b43e3e3cf7.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/file_000000002c8871fda19c9bf0d501686f.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/file_00000000742071fdaf9437c4c95c1af9.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/file_00000000d2387206ae00a5a75693a188 (1).png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/rust2.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/rust3.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/assets/wallpapers/wall.png -> home/config/noctalia/default.nix (recursive wallpaper directory)
PASS home/scripts/mcb-toolchain -> home/scripts/default.nix (builtins.readFile source)
```
## Gate 6 — Shell and runtime smoke checks

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
- Ownership evidence follow-up: `41de938c7dbdaab39df31cc063f8c04cf01414cb` — `docs: expand Task 8 ownership evidence`
- Final metadata follow-up: `51b7d4e527e872a968f15f3c15cdfd9c477b500b` — `docs: record final Task 8 evidence hash`
- Inventory metadata follow-up: `b85039b82c6309729d3853e50491d70976e591b0` — `docs: record current Task 8 report hash`
- Complete evidence report follow-up: `0ef31fd7f22f5024efd16c7c0c02db9e006cc7c1` — `docs: record complete Task 8 probe evidence`
- Report tip-identification follow-up: `583962d32ebaab461364c9c6b4f37b663fd83c15` — `docs: identify Task 8 report tip`
- Final evidence metadata correction: `463ca6193798148a4616f65d380e31ae3b3bfd32` — `docs: correct final Task 8 evidence metadata`
- Final report metadata: `a01a79cf0c8b4216146f6c0068d86e48b80bbdce` — `docs: finalize Task 8 report metadata`

The checked-out `HEAD` contains this Commit section and all report-only evidence updates; verify its exact hash with `git rev-parse HEAD`. The pre-existing `task-3-report.md` correction remains unstaged and excluded.


## Unresolved risks

1. Zsh startup remains runtime-unverified because `zsh` is unavailable on the host.
2. Niri/Noctalia and GUI application behavior remains runtime-unverified because no graphical session was launched and `noctalia-session` is unavailable.
3. NixOS platform behavior was evaluated on a host exposing `/etc/NIXOS`, but no activation or `nixos-rebuild` was run.
4. The Bash command in the brief names `home/scripts/*.sh`, while the repository's active `home/scripts/mcb-toolchain` is extensionless; the corrected available-script parse passed.
5. The existing upstream LibreOffice package warning recommends `libreoffice-stable`; it did not affect evaluation or the build and was not changed in this verification-only task.

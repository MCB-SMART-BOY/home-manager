# Configuration effect cleanup implementation plan

> **For agentic workers:** This plan is executed in the current repository after the read-only audit and its evidence review.

**Goal:** Remove repository-unreferenced configuration and redundant Niri packages, then make the standalone Niri feature provide every executable required by its active keybindings.

**Architecture:** Keep Home Manager native options as the owner of GTK, Starship, and desktop behavior. Delete only raw files proven to have no deployment path. Keep recursive theme/wallpaper assets and conditional NixOS/Niri files. Make `home/features/niri.nix` an explicit session dependency boundary instead of relying on unrelated optional feature composition.

**Tech Stack:** Nix, Home Manager, nixpkgs unstable, Niri, Noctalia.

**Spec:** `.agent/design.md`

## Global Constraints

- Do not delete `home/assets/themes/**` or `home/assets/wallpapers/**`; these are recursively deployed by active modules.
- Do not delete NixOS-only or Niri-only raw configuration files; they are conditionally deployed.
- GTK raw files under `home/config/gtk-{2,3,4}.0` are repository-unreferenced and must not be confused with the active theme assets under `home/assets/themes/**`.
- Noctalia remains the owner of launcher, bar, notification, lockscreen, wallpaper, clipboard-history, and polkit-agent behavior.
- `homeModules.niri` must not reference an executable that its own package composition does not provide, except explicitly documented host-provided services.

---

### Task 1: Remove confirmed orphan configuration

**Files:**
- Delete: `home/config/alacritty/alacritty.toml`
- Delete: `home/config/fuzzel/fuzzel.ini`
- Delete: `home/config/mako/config`
- Delete: `home/config/swaylock/config`
- Delete: `home/config/gtk-2.0/gtkrc`
- Delete: `home/config/gtk-3.0/settings.ini`
- Delete: `home/config/gtk-4.0/settings.ini`
- Delete: `home/config/starship/mokka.toml`

**Acceptance:** No Nix source references these paths; `home/assets/themes/**/gtk-*` remains intact.

### Task 2: Remove redundant Niri software

**Files:**
- Modify: `home/features/niri.nix`

Remove packages with no active configuration path or command reference:

```nix
polkit_gnome
waybar
walker
anyrun
swaynotificationcenter
swaylock-effects
swaybg
cliphist
wf-recorder
wlsunset
rofi
```

Retain `niri`, `noctalia`, `swayidle`, `steam`, and `satty`, plus the three local wrappers. Remove the unused `nixos-artwork.wallpapers.catppuccin-mocha` package from `home/features/theming.nix`; the active wallpaper source is the recursively deployed `home/assets/wallpapers` tree.

### Task 3: Declare Niri keybinding dependencies

**Files:**
- Modify: `home/features/niri.nix`

Add packages for active commands in `home/config/niri/*.kdl`:

```nix
kitty
nautilus
google-chrome
telegram-desktop
obs-studio
pavucontrol
keepassxc
mission-center
grim
slurp
wl-clipboard
playerctl
linux-wallpaperengine
```

The resulting package set must contain the binaries used by terminal, application, screenshot, media, and Noctalia W Engine bindings. `fcitx5` remains an explicit host/system dependency because this repository only deploys its profile/config files; `linux-wallpaperengine` is available in the pinned nixpkgs and should be added to the Niri feature.

### Task 4: Verify behavior and repository cleanliness

Run:

```bash
nix flake check --impure --no-write-lock-file --show-trace
env USER=alice HOME=/tmp/alice-final \
  home-manager build --impure --flake .#default --no-write-lock-file
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    c = f.lib.mkHomeConfiguration {
      system = builtins.currentSystem;
      username = "niri-audit";
      homeDirectory = "/tmp/niri-audit";
      modules = [ f.homeModules.niri ];
    };
    packageNames = map (p: p.pname or p.name or "") c.config.home.packages;
    required = [
      "noctalia" "kitty" "nautilus" "google-chrome" "telegram-desktop"
      "obs-studio" "pavucontrol" "keepassxc" "mission-center"
      "grim" "slurp" "wl-clipboard" "playerctl"
      "linux-wallpaperengine"
    ];
  in builtins.listToAttrs (map (name: {
    inherit name;
    value = builtins.any (pkg: builtins.match ("^.*" + name + ".*$") pkg != null) packageNames;
  }) required)
'
fish -n home/config/fish/config.fish home/config/fish/conf.d/*.fish home/config/fish/functions/*.fish
bash -n home/scripts/*.sh
```

The Niri probe must return `true` for every required package, and all eight orphan paths must be absent from the source tree. Inspect the final diff before committing.

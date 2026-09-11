# Home Manager architecture

## Decisions

- `flake.nix` remains a thin input declaration and imports `flake/default.nix`.
- `flake/default.nix` is the only composition/factory boundary. `mkPkgs` always enables `nixpkgs.config.allowUnfree = true`; no boolean policy option is threaded through callers.
- `lib.mkHomeConfiguration` accepts `system`, `username`, `homeDirectory`, and `modules ? []`. It composes `homeModules.default`, identity, and caller-selected modules.
- `homeModules.default` is the portable core. Optional capabilities are exposed only as cohesive `homeModules` under `home/features`.
- `home.shellAliases` is the single owner of simple cross-shell aliases. Fish uses `programs.fish.preferAbbrs = true`; shell-specific functions and structured Nushell commands remain shell-specific.
- Home Manager owns Starship, Zoxide, Direnv, Eza, and shared aliases. Raw shell assets retain only behavior that cannot be represented by Home Manager.
- Runtime programs longer than three shell lines do not live inside Nix expressions. They live under `home/scripts/` and are referenced by a short Nix module.
- Existing raw Fish/Zsh alias and integration blocks may be removed so Nix has one owner. Non-duplicated shell behavior remains.
- Feature modules own their packages, program settings, desktop entries, services, and assets. The legacy `profiles` namespace is not a public composition API.
- Durable workflow guidance lives under `.agent/`; production configuration lives under `flake/` and `home/`.

## Non-goals

- Do not add a generic profile DSL or a giant package attrset.
- Do not silently add currently unmapped assets.
- Do not claim runtime success for a desktop feature without a matching host.

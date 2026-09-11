# Verification workflow

Run from the repository root.

## Structural evaluation

```bash
nix flake check --impure --no-write-lock-file --show-trace
```

## Default standalone build

```bash
env USER=alice HOME=/tmp/alice-final \
  home-manager build --impure --flake .#default --no-write-lock-file
```

## Explicit arbitrary identity

```bash
nix eval --impure --json --expr '
  let f = builtins.getFlake (toString ./.);
  in (f.lib.mkHomeConfiguration {
    system = "x86_64-linux";
    username = "arbitrary-user";
    homeDirectory = "/tmp/arbitrary-home";
  }).config.home.homeDirectory
'
```

## Feature boundaries

Evaluate the default, development, Niri, NixOS, and full feature compositions explicitly. Every composition uses the repository-wide `allowUnfree = true` package policy.

## Asset integrity

```bash
nix hash path home/config
nix hash path home/assets
```

Do not treat an evaluator result as desktop runtime proof. Niri/Noctalia, systemd user services, host-provided commands, and activation on paths containing spaces require separate evidence.

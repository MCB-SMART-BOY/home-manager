#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo/tests/git-fixture.sh"
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
cat >"$fixture/flake.nix" <<'EOF'
{
  outputs = { self }: {
    nixosConfigurations = {
      alpha.options.testHost = "alpha";
      beta.options.testHost = "beta";
    };
  };
}
EOF
track_fixture_files "$fixture" flake.nix

cd "$repo"
profile=$(TEST_FLAKE_DIR="$fixture" nix eval --impure --offline --no-write-lock-file --json --expr '
  let
    flake = builtins.getFlake (toString ./.);
    lib = flake.inputs.nixpkgs.lib;
    portable = flake.homeConfigurations.default.config;
    nixos = flake.homeConfigurations.nixos.config;
    readable = (flake.lib.mkHomeConfiguration {
      system = builtins.currentSystem;
      username = "profile-test";
      homeDirectory = "/tmp/profile-test";
      modules = [
        flake.homeModules.nixvim
        flake.homeModules.nixos
        { mcb.nixos.flakeDirectory = builtins.getEnv "TEST_FLAKE_DIR"; }
      ];
    }).config;
    helix = config: config.programs.helix.languages."language-server";
    nixvimHost = config: lib.attrByPath
      [ "programs" "nixvim" "lsp" "servers" "nixd" "config" "settings" "nixd" ]
      null config;
  in {
    portable = {
      hasNixosPackage = builtins.any (package: lib.hasInfix "mcb-nixos" (package.name or "")) portable.home.packages;
      helixHost = (helix portable).nixd.config or null;
      nixvimHost = nixvimHost portable;
    };
    nixos = {
      directory = nixos.mcb.nixos.flakeDirectory;
      hostEnabled = nixos.mcb.nixos.enableHostOptions;
      hasNixosPackage = builtins.any (package: lib.hasInfix "mcb-nixos" (package.name or "")) nixos.home.packages;
      helixHost = (helix nixos).nixd.config or null;
      nixvimHost = nixvimHost nixos;
      helixNixd = (helix nixos).nixd.command;
      clangdHasNixosDriver = builtins.any (arg: lib.hasInfix "--query-driver=" arg) (helix nixos).clangd.args;
      nixvimClangdHasNixosDriver = builtins.any (arg: lib.hasInfix "--query-driver=" arg) nixos.programs.nixvim.lsp.servers.clangd.config.cmd;
    };
    readable = {
      directory = readable.mcb.nixos.flakeDirectory;
      hostEnabled = readable.mcb.nixos.enableHostOptions;
      helixHost = (helix readable).nixd.config;
      nixvimHost = nixvimHost readable;
    };
  }
')

jq -e --arg fixture "$fixture" '
  .portable.hasNixosPackage == false and
  .portable.helixHost == null and
  .portable.nixvimHost == null and
  .nixos.directory == "/root/nixos-config" and
  .nixos.hostEnabled == false and
  .nixos.hasNixosPackage == true and
  .nixos.helixHost == null and
  .nixos.nixvimHost == null and
  .nixos.helixNixd == "nixd" and
  .nixos.clangdHasNixosDriver == true and
  .nixos.nixvimClangdHasNixosDriver == true and
  .readable.directory == $fixture and
  .readable.hostEnabled == true and
  .readable.helixHost.options.nixos.expr != null and
  .readable.nixvimHost.options.nixos.expr != null
' <<<"$profile" >/dev/null || fail 'portable, isolated, or readable editor configuration differs'

for editor in helixHost nixvimHost; do
  options_expr=$(jq -r --arg editor "$editor" '.readable[$editor].options.nixos.expr' <<<"$profile")
  selected_host=$(env -u MCB_NIXOS_FLAKE_DIR MCB_NIXOS_FLAKE_TARGET=beta NIXD_HOST=alpha \
    nix eval --impure --offline --no-write-lock-file --raw --expr "($options_expr).testHost")
  [[ "$selected_host" == beta ]] || fail "$editor did not select the explicit readable host"

  if MCB_NIXOS_FLAKE_DIR="$fixture" MCB_NIXOS_FLAKE_TARGET=missing \
    nix eval --impure --offline --no-write-lock-file --raw --expr "($options_expr).testHost" >/dev/null 2>&1; then
    fail "$editor unexpectedly selected an unknown host"
  fi
done

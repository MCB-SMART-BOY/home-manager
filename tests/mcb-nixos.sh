#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

cat >"$fixture/flake.nix" <<'EOF'
{
  outputs = { self }: {
    nixosConfigurations = {
      alpha = {};
      nixos = {};
    };
  };
}
EOF

source_output="$(MCB_NIXOS_FLAKE_DIR="$fixture" bash "$repo/home/platform/mcb-nixos" source)"
[[ "$source_output" == "path:$fixture" ]] || fail "source output was '$source_output'"

target_output="$(MCB_NIXOS_FLAKE_DIR="$fixture" bash "$repo/home/platform/mcb-nixos" target)"
[[ "$target_output" == "nixos" ]] || fail "hostname target output was '$target_output'"

ref_output="$(MCB_NIXOS_FLAKE_DIR="$fixture" MCB_NIXOS_FLAKE_TARGET=alpha bash "$repo/home/platform/mcb-nixos" ref)"
[[ "$ref_output" == "path:$fixture#alpha" ]] || fail "explicit ref output was '$ref_output'"

host_target_output="$(MCB_NIXOS_FLAKE_DIR="$fixture" NIXD_HOST=alpha bash "$repo/home/platform/mcb-nixos" target)"
[[ "$host_target_output" == "alpha" ]] || fail "NIXD_HOST target output was '$host_target_output'"

if MCB_NIXOS_FLAKE_DIR="$fixture" MCB_NIXOS_FLAKE_TARGET=missing bash "$repo/home/platform/mcb-nixos" target; then
  fail "invalid explicit target must fail"
fi

if MCB_NIXOS_FLAKE_DIR= bash "$repo/home/platform/mcb-nixos" source; then
  fail "empty source must resolve to /etc/nixos and fail when it is not a flake"
fi

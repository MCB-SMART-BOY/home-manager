#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
symlink_root="$(mktemp -d)"
flake_symlink_root="$(mktemp -d)"
singleton_fixture="$(mktemp -d)"
trap 'rm -rf "$fixture" "$symlink_root" "$flake_symlink_root" "$singleton_fixture"' EXIT

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

cat >"$singleton_fixture/flake.nix" <<'EOF'
{
  outputs = { self }: {
    nixosConfigurations = {
      solo = {};
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

precedence_target_output="$(MCB_NIXOS_FLAKE_DIR="$fixture" MCB_NIXOS_FLAKE_TARGET=alpha NIXD_HOST=nixos bash "$repo/home/platform/mcb-nixos" target)"
[[ "$precedence_target_output" == "alpha" ]] || fail "explicit target precedence output was '$precedence_target_output'"

if env -u MCB_NIXOS_FLAKE_TARGET MCB_NIXOS_FLAKE_DIR="$fixture" NIXD_HOST=missing bash "$repo/home/platform/mcb-nixos" target; then
  fail "invalid NIXD_HOST target must fail"
fi

ln -s "$fixture" "$symlink_root/link"
if MCB_NIXOS_FLAKE_DIR="$symlink_root/link" bash "$repo/home/platform/mcb-nixos" source; then
  fail "direct symlink source must fail"
fi

ln -s "$fixture/flake.nix" "$flake_symlink_root/flake.nix"
if MCB_NIXOS_FLAKE_DIR="$flake_symlink_root" bash "$repo/home/platform/mcb-nixos" source; then
  fail "symlinked flake.nix must fail"
fi

if MCB_NIXOS_FLAKE_DIR="$fixture" MCB_NIXOS_FLAKE_TARGET=missing bash "$repo/home/platform/mcb-nixos" target; then
  fail "invalid explicit target must fail"
fi

singleton_target_output="$(env -u MCB_NIXOS_FLAKE_TARGET -u NIXD_HOST MCB_NIXOS_FLAKE_DIR="$singleton_fixture" bash "$repo/home/platform/mcb-nixos" target)"
[[ "$singleton_target_output" == "solo" ]] || fail "singleton target output was '$singleton_target_output'"

unset_stdout="$fixture/unset-source.stdout"
unset_stderr="$fixture/unset-source.stderr"
empty_stdout="$fixture/empty-source.stdout"
empty_stderr="$fixture/empty-source.stderr"
set +e
env -u MCB_NIXOS_FLAKE_DIR bash "$repo/home/platform/mcb-nixos" source >"$unset_stdout" 2>"$unset_stderr"
unset_status=$?
MCB_NIXOS_FLAKE_DIR= bash "$repo/home/platform/mcb-nixos" source >"$empty_stdout" 2>"$empty_stderr"
empty_status=$?
set -e
[[ "$unset_status" == "$empty_status" ]] || fail "unset and empty source statuses differ: $unset_status vs $empty_status"
if ! cmp -s "$unset_stdout" "$empty_stdout"; then
  fail "unset and empty source stdout differs"
fi
if ! cmp -s "$unset_stderr" "$empty_stderr"; then
  fail "unset and empty source stderr differs"
fi

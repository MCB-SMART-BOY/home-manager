#!/usr/bin/env bash
# Project-local checks only; run the independent global quality gate afterward.
set -uo pipefail

show_help() {
  printf '%s\n' \
    'Usage: bash .omp/validate.sh [--help|-h]' \
    'Run project checks without switching profiles, changing the lock, or using sudo.' \
    'Requires Nix and the project devShell tools. If tools are missing, run:' \
    '  nix develop --no-write-lock-file --command bash .omp/validate.sh'
}

if [[ $# -ne 0 ]]; then
  if [[ $# -eq 1 && ( $1 == --help || $1 == -h ) ]]; then
    show_help
    exit 0
  fi
  printf 'validate.sh: invalid arguments\n' >&2
  show_help >&2
  exit 2
fi

script_dir=${BASH_SOURCE[0]%/*}
[[ $script_dir == "${BASH_SOURCE[0]}" ]] && script_dir=.
repo=$(cd -- "$script_dir/.." && pwd) || exit 1
cd "$repo" || exit 1

missing=0
for tool in bash nix shellcheck jq git dirname mktemp rm chmod mkdir cp ln env cat tr sed; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '[MISSING] required tool: %s\n' "$tool" >&2
    missing=1
  fi
done
if [[ $EUID -eq 0 ]] && ! command -v setpriv >/dev/null 2>&1; then
  printf '[MISSING] required tool for root-run tests: setpriv\n' >&2
  missing=1
fi
if [[ $missing -ne 0 ]]; then
  printf 'Install Nix first if missing, then run from this project: nix develop --no-write-lock-file --command bash .omp/validate.sh\n' >&2
  exit 1
fi

status=0
run_check() {
  local label=$1
  local exit_code
  shift
  printf '\n[CHECK] %s\n' "$label"
  if "$@"; then
    printf '[PASS] %s\n' "$label"
  else
    exit_code=$?
    printf '[FAIL] %s (exit %s)\n' "$label" "$exit_code" >&2
    status=1
  fi
}

run_check 'ShellCheck (project Bash files)' shellcheck --shell=bash -x \
  .omp/validate.sh .omp/tests/*.sh home/platform/mcb-nixos home/scripts/mcb-toolchain
run_check 'mcb-toolchain.sh' bash .omp/tests/mcb-toolchain.sh
run_check 'mcb-nixos.sh' bash .omp/tests/mcb-nixos.sh
run_check 'default-profile.sh' bash .omp/tests/default-profile.sh
run_check 'nixos-profile.sh' bash .omp/tests/nixos-profile.sh
run_check 'default activationPackage' nix build --impure --no-write-lock-file --no-link \
  '.#homeConfigurations.default.activationPackage'

if [[ -e /etc/NIXOS ]]; then
  run_check 'nixos activationPackage' nix build --impure --no-write-lock-file --no-link \
    '.#homeConfigurations.nixos.activationPackage'
else
  printf '\n[SKIP] nixos activationPackage (/etc/NIXOS absent; not applicable)\n'
fi

if [[ $status -eq 0 ]]; then
  printf '\nProject validation PASSED; run the independent global quality gate next.\n'
else
  printf '\nProject validation FAILED; review the [FAIL] results above.\n' >&2
fi

exit "$status"

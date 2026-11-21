#!/usr/bin/env bash
# Project-local checks only; run the independent global quality gate afterward.
set -uo pipefail

show_help() {
  printf '%s\n' \
    'Usage: bash .omp/validate.sh [--help|-h]' \
    'Build the #home activation package for the current user without activating it.' \
    'Requires Nix and jq; runs the toolchain fixture without installing tools.'
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

if ! command -v nix >/dev/null 2>&1; then
  printf 'validate.sh: Nix is required; install it before running this check.\n' >&2
  exit 1
fi

bash .omp/tests/toolchain.sh || exit

exec nix build --impure --no-update-lock-file --no-link \
  '.#homeConfigurations.home.activationPackage'

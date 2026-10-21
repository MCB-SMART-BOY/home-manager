#!/usr/bin/env bash
# Run project behavior checks before ~/.omp/agent/validate.sh.
# The global validator builds the flake checks but does not discover these tests.
# This entry point never activates a profile, changes a lock, or invokes sudo.
set -uo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
status=0
checks=(
  mcb-toolchain.sh
  mcb-nixos.sh
  default-profile.sh
  nixos-profile.sh
)

for check in "${checks[@]}"; do
  printf '\n[CHECK] %s\n' "$check"
  if bash "$repo/tests/$check"; then
    printf '[PASS] %s\n' "$check"
  else
    printf '[FAIL] %s\n' "$check" >&2
    status=1
  fi
done

exit "$status"

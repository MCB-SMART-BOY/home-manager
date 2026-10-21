#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo/.omp/tests/git-fixture.sh"
fixture="$(mktemp -d)"
symlink_root="$(mktemp -d)"
flake_symlink_root="$(mktemp -d)"
singleton_fixture="$(mktemp -d)"
cleanup() {
  chmod -R u+rwx "$fixture"
  rm -rf "$fixture" "$symlink_root" "$flake_symlink_root" "$singleton_fixture"
}
trap cleanup EXIT

cat >"$fixture/flake.nix" <<'EOF'
{
  outputs = { self }: {
    nixosConfigurations = {
      alpha = {};
      nixos = {};
    };
    visibility = {
      untracked = builtins.pathExists ./untracked-note;
      ignored = builtins.pathExists ./ignored-note;
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

if MCB_NIXOS_FLAKE_DIR="$fixture" bash "$repo/home/platform/mcb-nixos" source; then
  fail "non-Git source must be rejected before importing it"
fi
printf '%s\n' ignored-note >"$fixture/.gitignore"
printf '%s\n' 'harmless untracked marker' >"$fixture/untracked-note"
printf '%s\n' 'harmless ignored marker' >"$fixture/ignored-note"
track_fixture_files "$fixture" flake.nix .gitignore
track_fixture_files "$singleton_fixture" flake.nix

source_output="$(MCB_NIXOS_FLAKE_DIR="$fixture" bash "$repo/home/platform/mcb-nixos" source)"
[[ "$source_output" == "$fixture" ]] || fail "source output was '$source_output'"
visibility=$(nix eval --offline --no-write-lock-file --json "$source_output#visibility")
jq -e '.ignored == false and .untracked == false' <<<"$visibility" >/dev/null ||
  fail "source import must exclude ignored and untracked files"

untracked_source="$fixture/untracked-source"
mkdir "$untracked_source"
cp "$fixture/flake.nix" "$untracked_source/flake.nix"
printf '%s\n' ignored-note >"$untracked_source/.gitignore"
track_fixture_files "$untracked_source" .gitignore
if MCB_NIXOS_FLAKE_DIR="$untracked_source" bash "$repo/home/platform/mcb-nixos" source; then
  fail "untracked flake.nix must be rejected before importing it"
fi

expected_hostname_target=nixos
if [[ -r /etc/hostname ]]; then
  hostname_target=$(< /etc/hostname)
  case "$hostname_target" in
    alpha|nixos) expected_hostname_target=$hostname_target ;;
  esac
fi
target_output="$(env -u MCB_NIXOS_FLAKE_TARGET -u NIXD_HOST MCB_NIXOS_FLAKE_DIR="$fixture" bash "$repo/home/platform/mcb-nixos" target)"
[[ "$target_output" == "$expected_hostname_target" ]] || fail "hostname target output was '$target_output' (expected '$expected_hostname_target')"

ref_output="$(MCB_NIXOS_FLAKE_DIR="$fixture" MCB_NIXOS_FLAKE_TARGET=alpha bash "$repo/home/platform/mcb-nixos" ref)"
[[ "$ref_output" == "$fixture#alpha" ]] || fail "explicit ref output was '$ref_output'"

host_target_output="$(env -u MCB_NIXOS_FLAKE_TARGET MCB_NIXOS_FLAKE_DIR="$fixture" NIXD_HOST=alpha bash "$repo/home/platform/mcb-nixos" target)"
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

for invalid_source in relative 'https://example.org/config' "$fixture/missing"; do
  if MCB_NIXOS_FLAKE_DIR="$invalid_source" bash "$repo/home/platform/mcb-nixos" source; then
    fail "invalid source '$invalid_source' must fail"
  fi
done

readonly UNPRIVILEGED_ID=65534
run_unprivileged() {
  if [[ $EUID -eq 0 ]]; then
    command -v setpriv >/dev/null || fail "root test run requires setpriv"
    setpriv --reuid="$UNPRIVILEGED_ID" --regid="$UNPRIVILEGED_ID" --clear-groups \
      bash "$fixture/mcb-nixos" "$@"
  else
    bash "$repo/home/platform/mcb-nixos" "$@"
  fi
}

if [[ $EUID -eq 0 ]]; then
  cp "$repo/home/platform/mcb-nixos" "$fixture/mcb-nixos"
  chmod 755 "$fixture" "$fixture/mcb-nixos"
fi

restricted_source="$fixture/restricted-source"
mkdir "$restricted_source"
chmod 000 "$restricted_source"
if MCB_NIXOS_FLAKE_DIR="$restricted_source" run_unprivileged source >"$fixture/restricted.stdout"; then
  fail "inaccessible source must fail for an ordinary user"
fi
[[ ! -s "$fixture/restricted.stdout" ]] || fail "inaccessible source must not print a reference"

fake_bin="$fixture/fake-bin"
probe_dir="$fixture/probes"
mkdir "$fake_bin" "$probe_dir"
chmod 777 "$probe_dir"
for command_name in sudo nix nixos-rebuild; do
  cat >"$fake_bin/$command_name" <<'EOF'
#!/usr/bin/env bash
: >"$MCB_TEST_PROBE"
exit 99
EOF
  chmod +x "$fake_bin/$command_name"
done

# A non-root request must fail before either evaluating the source or escalating.
for operation in switch test boot update update-switch; do
  if PATH="$fake_bin:$PATH" MCB_TEST_PROBE="$probe_dir/called" \
    MCB_NIXOS_FLAKE_DIR="$fixture" run_unprivileged "$operation"; then
    fail "$operation must require root"
  fi
  [[ ! -e "$probe_dir/called" ]] || fail "$operation evaluated or escalated before requiring root"
done

# Exercise the real Nix dry-run with an unlocked local input. The deliberately
# unavailable builder makes an accidental real build fail instead of executing.
dry_run_fixture="$fixture/dry-run"
mkdir -p "$dry_run_fixture/input"
printf '%s\n' '{ outputs = { self }: { }; }' >"$dry_run_fixture/input/flake.nix"
system=$(nix eval --impure --offline --raw --expr 'builtins.currentSystem')
cat >"$dry_run_fixture/flake.nix" <<EOF
{
  inputs.local.url = "path:./input";
  outputs = { self, local }: {
    checkTarget = builtins.derivation {
      name = "mcb-nixos-dry-run";
      system = "$system";
      builder = "/mcb-nixos-must-not-build";
    };
    nixosConfigurations."host.example".config.system.build.toplevel = self.checkTarget;
  };
}
EOF
track_fixture_files "$dry_run_fixture" flake.nix input/flake.nix
(
  cd "$dry_run_fixture"
  bash "$repo/home/platform/mcb-nixos" check "$dry_run_fixture#checkTarget"
  MCB_NIXOS_FLAKE_DIR="$dry_run_fixture" MCB_NIXOS_FLAKE_TARGET=host.example \
    bash "$repo/home/platform/mcb-nixos" check
)
[[ ! -e "$dry_run_fixture/flake.lock" ]] || fail "check must not write the source lock"
[[ ! -e "$dry_run_fixture/result" ]] || fail "check must not create a result link"

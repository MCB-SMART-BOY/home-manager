#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export HOME="$fixture/home" CARGO_INSTALL_ROOT="$fixture/cargo" TOOLCHAIN_LOG="$fixture/actions"
mkdir -p "$HOME" "$CARGO_INSTALL_ROOT/bin" "$fixture/bin" "$fixture/go"
cat > "$fixture/bin/manager" <<'MANAGER'
#!/usr/bin/env bash
set -eu
[[ $PWD == "$HOME" ]]
case ${0##*/}:$* in
  'cargo:install --list --root '*) printf 'ripgrep v1.0.0:\n    rg\n' ;;
  'uv:tool dir --bin') printf '%s/uv\n' "$HOME" ;;
  'uv:tool list') printf 'ruff v1.0.0\n- ruff\n' ;;
  'go:env -json GOBIN GOPATH') printf '{"GOBIN":"","GOPATH":"%s/go:%s/old-go"}\n' "$HOME" "$HOME" ;;
  'go:version -m '*) printf '\tpath\tother.example/not-shfmt\n' ;;
  'bun:pm bin --global') printf '%s/bun\n' "$HOME" ;;
  'bun:pm ls --global') printf 'Global package list\n└── @vtsls/language-server@1.0.0\n' ;;
  'mise:ls --global --json') printf '{"uv":[{"installed":true,"active":true}],"node":[{"installed":true,"active":false}]}\n' ;;
  *) printf '%s %s\n' "${0##*/}" "$*" >> "$TOOLCHAIN_LOG" ;;
esac
MANAGER
chmod +x "$fixture/bin/manager"
for name in cargo uv go bun mise; do ln -s manager "$fixture/bin/$name"; done
# These commands are deliberately visible earlier in PATH, not owned by the managers.
for name in node rg fd prettier; do ln -s "$(type -P bash)" "$fixture/bin/$name"; done
printf '#!/bin/sh\nexit 0\n' > "$CARGO_INSTALL_ROOT/bin/rg"
chmod +x "$CARGO_INSTALL_ROOT/bin/rg"
mkdir -p "$HOME/go/bin"
ln -s "$(type -P bash)" "$HOME/go/bin/shfmt"
export PATH="$fixture/bin:$PATH"

run_tools() { bash "$repo/home/scripts/toolchain" "$repo/home/scripts/toolchain.tsv" "$@"; }

run_tools bootstrap > "$fixture/bootstrap.log"
grep -Fx "cargo install --locked --root $CARGO_INSTALL_ROOT fd-find" "$TOOLCHAIN_LOG"
grep -Fx "cargo install --locked --root $CARGO_INSTALL_ROOT ripgrep" "$TOOLCHAIN_LOG"
grep -Fx 'uv tool install --managed-python --upgrade ty' "$TOOLCHAIN_LOG"
grep -Fx 'go install mvdan.cc/sh/v3/cmd/shfmt@latest' "$TOOLCHAIN_LOG"
grep -Fx 'bun add --global prettier@latest' "$TOOLCHAIN_LOG"
if grep -q '^mise ' "$TOOLCHAIN_LOG"; then
  printf 'bootstrap selected global mise tools without being asked\n' >&2
  exit 1
fi

: > "$TOOLCHAIN_LOG"
run_tools update rust python go js mise > "$fixture/update.log"
diff -u - "$TOOLCHAIN_LOG" <<EXPECTED
cargo install --locked --root $CARGO_INSTALL_ROOT ripgrep
uv tool install --managed-python --upgrade ruff
bun add --global @vtsls/language-server@latest
mise use --global --fuzzy uv@latest
EXPECTED

: > "$TOOLCHAIN_LOG"
if run_tools check rust > "$fixture/check.log" 2>&1; then
  printf 'check incorrectly accepted the system fd as a Cargo installation\n' >&2
  exit 1
fi
grep -F "rg: $CARGO_INSTALL_ROOT/bin/rg (PATH: $fixture/bin/rg)" "$fixture/check.log"
grep -F 'rust/fd-find: not installed by cargo' "$fixture/check.log"
test ! -s "$TOOLCHAIN_LOG"

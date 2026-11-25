#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export HOME="$fixture/home" CARGO_INSTALL_ROOT="$fixture/cargo" TOOLCHAIN_LOG="$fixture/actions"
mkdir -p "$HOME" "$CARGO_INSTALL_ROOT/bin" "$fixture/bin" "$HOME/bun"
cat > "$fixture/bin/manager" <<'MANAGER'
#!/usr/bin/env bash
set -eu
[[ $PWD == "$HOME" ]]
case ${0##*/}:$* in
  'cargo:install --list --root '*) printf 'taplo-cli v1.0.0:\n    taplo\nstylua v1.0.0:\n    stylua\n' ;;
  'uv:tool dir --bin') printf '%s/uv\n' "$HOME" ;;
  'uv:tool list') printf 'ruff v1.0.0\n- ruff\n' ;;
  'go:env -json GOBIN GOPATH') printf '{"GOBIN":"","GOPATH":"%s/go:%s/old-go"}\n' "$HOME" "$HOME" ;;
  'go:version -m '*) printf '\tpath\tother.example/not-installed\n' ;;
  'bun:pm bin --global') printf '%s/bun\n' "$HOME" ;;
  'bun:pm ls --global') printf 'Global package list\n└── @vtsls/language-server@1.0.0\n' ;;
  *) printf '%s %s\n' "${0##*/}" "$*" >> "$TOOLCHAIN_LOG" ;;
esac
MANAGER
chmod +x "$fixture/bin/manager"
for name in cargo uv go bun; do ln -s manager "$fixture/bin/$name"; done
# These commands are deliberately visible earlier in PATH, not owned by the managers.
for name in node rg fd prettier taplo; do ln -s "$(type -P bash)" "$fixture/bin/$name"; done
printf '#!/bin/sh\nexit 0\n' > "$CARGO_INSTALL_ROOT/bin/taplo"
printf '#!/bin/sh\nexit 0\n' > "$CARGO_INSTALL_ROOT/bin/stylua"
chmod +x "$CARGO_INSTALL_ROOT/bin/taplo" "$CARGO_INSTALL_ROOT/bin/stylua"
ln -s "$CARGO_INSTALL_ROOT/bin/stylua" "$fixture/bin/stylua"
mkdir -p "$HOME/go/bin"
ln -s "$(type -P bash)" "$HOME/go/bin/shfmt"
export PATH="$fixture/bin:$PATH"

run_tools() { bash "$repo/home/modules/development/toolchain/toolchain" "$repo/home/modules/development/toolchain/manifest.tsv" "$@"; }

run_tools bootstrap > "$fixture/bootstrap.log"
grep -Fx "cargo install --locked --root $CARGO_INSTALL_ROOT taplo-cli" "$TOOLCHAIN_LOG"
grep -Fx "cargo install --locked --root $CARGO_INSTALL_ROOT stylua" "$TOOLCHAIN_LOG"
grep -Fx 'uv tool install --managed-python --upgrade ruff' "$TOOLCHAIN_LOG"
grep -Fx 'uv tool install --managed-python --upgrade ty' "$TOOLCHAIN_LOG"
grep -Fx 'go install golang.org/x/tools/gopls@latest' "$TOOLCHAIN_LOG"
grep -Fx 'go install mvdan.cc/gofumpt@latest' "$TOOLCHAIN_LOG"
if grep -Eq 'cargo install --locked --root .* (ripgrep|fd-find|bat|eza|ouch)$' "$TOOLCHAIN_LOG"; then
  printf 'bootstrap reinstalled commands owned by Nix\n' >&2
  exit 1
fi

: > "$TOOLCHAIN_LOG"
run_tools update rust python go js > "$fixture/update.log"
diff -u - "$TOOLCHAIN_LOG" <<EXPECTED
cargo install --locked --root $CARGO_INSTALL_ROOT taplo-cli
cargo install --locked --root $CARGO_INSTALL_ROOT stylua
uv tool install --managed-python --upgrade ruff
bun add --global @vtsls/language-server@latest
EXPECTED

: > "$TOOLCHAIN_LOG"
if run_tools check rust > "$fixture/check.log" 2>&1; then
  printf 'check incorrectly accepted a shadowed Cargo executable\n' >&2
  exit 1
fi
grep -F "taplo: expected $CARGO_INSTALL_ROOT/bin/taplo, but PATH resolves to $fixture/bin/taplo" "$fixture/check.log"
grep -F "stylua: $CARGO_INSTALL_ROOT/bin/stylua (active)" "$fixture/check.log"
test ! -s "$TOOLCHAIN_LOG"

: > "$TOOLCHAIN_LOG"
if run_tools check mise > "$fixture/mise.log" 2>&1; then
  printf 'check accepted a removed tool group\n' >&2
  exit 1
fi
grep -F 'Unknown tool group: mise' "$fixture/mise.log"
test ! -s "$TOOLCHAIN_LOG"

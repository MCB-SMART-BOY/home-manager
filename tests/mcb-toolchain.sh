#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/config/toolchain"
cat >"$tmp/config/toolchain/tools.json" <<'EOF'
{
  "rust": {},
  "lean": {},
  "opam": [],
  "cargo": [{"package": "failing-tool", "binary": "failing-tool"}],
  "go": [],
  "uv": [],
  "bun": []
}
EOF

for manager in opam go uv bun; do
  cat >"$tmp/bin/$manager" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$tmp/bin/$manager"
done

cat >"$tmp/bin/cargo" <<'EOF'
#!/usr/bin/env bash
exit 17
EOF
chmod +x "$tmp/bin/cargo"

if HOME="$tmp" XDG_CONFIG_HOME="$tmp/config" PATH="$tmp/bin:$PATH" \
  bash "$repo/home/scripts/mcb-toolchain" bootstrap; then
  printf '%s\n' 'bootstrap unexpectedly succeeded after cargo failure' >&2
  exit 1
fi

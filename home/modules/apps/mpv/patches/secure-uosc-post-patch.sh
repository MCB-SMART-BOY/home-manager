set -eu
fail() {
  echo "secureUosc: $*" >&2
  exit 1
}

main=src/uosc/main.lua
menus=src/uosc/lib/menus.lua
updater=src/uosc/elements/Updater.lua

test -f "$main" || fail "missing $main"
test -f "$menus" || fail "missing $menus"
test -f "$updater" || fail "missing $updater"

require_marker() {
  grep -Fq -- "$1" "$2" || fail "missing marker '$1' in $2"
}

require_marker "open_subtitles_api_key" "$main"
require_marker "open_subtitles_agent" "$main"
require_marker "Update uosc" "$main"
require_marker "bind_command('update', function()" "$main"
require_marker "bind_command('download-subtitles', open_subtitle_downloader)" "$main"
require_marker "download_command = 'script-binding uosc/download-subtitles'" "$main"
require_marker "function open_subtitle_downloader()" "$menus"

test "$(awk '/^function open_subtitle_downloader\(\)$/ { print NR; exit }' "$menus")" = 887 \
  || fail "unexpected subtitle downloader line"
test "$(wc -l < "$menus")" = 1138 \
  || fail "unexpected menus.lua length"

sed -i \
  -e "/open_subtitles_api_key =/d" \
  -e "/open_subtitles_agent =/d" \
  -e "/title = t('Update uosc')/d" \
  -e "/bind_command('update', function()/,+2d" \
  -e "/bind_command('download-subtitles'/d" \
  -e "/download_command = 'script-binding uosc\\/download-subtitles'/d" \
  "$main"
sed -i '/^function open_subtitle_downloader()/,$d' "$menus"
rm -- "$updater"

assert_absent() {
  if grep -Fq -- "$1" "$2"; then
    fail "forbidden marker '$1' remains in $2"
  fi
}

for marker in \
  "Update uosc" \
  "uosc/update" \
  "download-subtitles" \
  "open_subtitles_api_key" \
  "open_subtitles_agent" \
  "open_subtitle_downloader" \
  "elements/Updater"; do
  assert_absent "$marker" "$main"
  assert_absent "$marker" "$menus"
done
tree_absent() {
  if grep -R -Fq -- "$1" src/uosc; then
    fail "forbidden tree marker '$1' remains"
  fi
}

for marker in \
  "raw.githubusercontent.com" \
  "api.github.com/repos/tomasklaen/uosc" \
  "api.opensubtitles.com" \
  "curl -fsSL" \
  "irm " \
  "download-subtitles" \
  "search-subtitles" \
  "open_subtitles" \
  "Updater.lua" \
  "elements/Updater"; do
  tree_absent "$marker"
done
if grep -R -E -q -- "['\"]https?://" src/uosc; then
  fail "runtime URL literal remains in src/uosc"
fi
test ! -e "$updater" || fail "$updater still exists"

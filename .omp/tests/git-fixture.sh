#!/usr/bin/env bash
# Git objects and indexes here belong only to caller-created temporary fixtures.
# No commits are created and the project's Git metadata is never modified.

run_fixture_git() {
  local directory=$1
  shift
  env -i PATH="$PATH" HOME="$directory" \
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    GIT_DIR="$directory/.git" GIT_WORK_TREE="$directory" \
    GIT_INDEX_FILE="$directory/.git/index" \
    git -C "$directory" "$@"
}

track_fixture_files() {
  local directory=$1
  local file object
  local -r regular_file_mode=100644
  shift
  if [[ -e "$directory/.git" ]]; then
    printf 'Refusing to initialize an existing Git fixture: %s\n' "$directory" >&2
    return 1
  fi
  run_fixture_git "$directory" init --quiet || return 1
  for file in "$@"; do
    object=$(run_fixture_git "$directory" hash-object -w -- "$file") || return 1
    run_fixture_git "$directory" update-index --add --cacheinfo \
      "$regular_file_mode" "$object" "$file" || return 1
  done
}

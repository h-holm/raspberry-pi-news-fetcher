#!/usr/bin/env bats
load test_helper

@test "runs housekeeping and then the sync with the reader's config" {
  export READERS_DIR="$WORK/readers"
  mkdir -p "$READERS_DIR"
  printf 'Fokus\n' >"$READERS_DIR/r.sources"
  cat >"$READERS_DIR/r.conf" <<CONF
SOURCES_FILE="r.sources"
TARGET_DIR="$WORK/local"
RCLONE_REMOTE="fake"
REMOTE_DIR="kobo"
FROM_DIR="$WORK/fetched"
CONF
  epub "Fokus-2026-11-06-1500.epub" 1 "$WORK/fetched"
  touch "$WORK/remote/kobo/RCLONE_TEST" "$WORK/remote/kobo/book.epub"
  run "$SCRIPTS/run_reader.sh" r
  [ "$status" -eq 0 ]
  [ -e "$WORK/local/Fokus-2026-11-06-1500.epub" ]
  [ -e "$WORK/local/RCLONE_TEST" ]
  grep -q "^bisync $WORK/local fake:/kobo" "$FAKE_CALLS"
}

@test "an unknown reader exits 2" {
  export READERS_DIR="$WORK/readers"
  mkdir -p "$READERS_DIR"
  run "$SCRIPTS/run_reader.sh" nobody
  [ "$status" -eq 2 ]
}

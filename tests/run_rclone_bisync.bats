#!/usr/bin/env bats
load test_helper

bisync() {
  "$SCRIPTS/run_rclone_bisync.sh" --local-dropbox-dir "$WORK/local" --remote-name fake \
    --remote-dropbox-dir kobo "$@"
}

@test "creates missing sentinels on non-empty sides and runs a checked bisync" {
  touch "$WORK/local/book.epub" "$WORK/remote/kobo/book.epub"
  run bisync
  [ "$status" -eq 0 ]
  [ -e "$WORK/local/RCLONE_TEST" ]
  [ -e "$WORK/remote/kobo/RCLONE_TEST" ]
  grep -q -- "--check-access" "$FAKE_CALLS"
  grep -q "fake:/kobo" "$FAKE_CALLS"
}

@test "an empty local side holding only the sentinel syncs fine" {
  touch "$WORK/local/RCLONE_TEST" "$WORK/remote/kobo/RCLONE_TEST" "$WORK/remote/kobo/old.epub"
  run bisync
  [ "$status" -eq 0 ]
}

@test "a completely empty local dir is treated as a wipe: no sync" {
  touch "$WORK/remote/kobo/RCLONE_TEST" "$WORK/remote/kobo/book.epub"
  run bisync
  [ "$status" -eq 1 ]
  [[ $output == *"completely empty"* ]]
  [ ! -s "$FAKE_CALLS" ]
}

@test "a completely empty remote is treated as a wipe: no sync" {
  touch "$WORK/local/RCLONE_TEST" "$WORK/local/book.epub"
  run bisync
  [ "$status" -eq 1 ]
  [ ! -s "$FAKE_CALLS" ]
}

@test "--init creates sentinels even on empty sides" {
  run bisync --init
  [ "$status" -eq 0 ]
  [ -e "$WORK/local/RCLONE_TEST" ]
  [ -e "$WORK/remote/kobo/RCLONE_TEST" ]
  grep -q -- "--resync-mode newer" "$FAKE_CALLS"
}

@test "automatically resyncs once when bisync demands it" {
  touch "$WORK/local/RCLONE_TEST" "$WORK/remote/kobo/RCLONE_TEST"
  export FAKE_BISYNC_MODE=needs-resync
  run bisync
  [ "$status" -eq 0 ]
  [ "$(grep -c '^bisync' "$FAKE_CALLS")" -eq 2 ]
  tail -n 1 "$FAKE_CALLS" | grep -q -- "--resync-mode newer"
}

@test "does not resync after a retryable error" {
  touch "$WORK/local/RCLONE_TEST" "$WORK/remote/kobo/RCLONE_TEST"
  export FAKE_BISYNC_MODE=fail
  run bisync
  [ "$status" -eq 1 ]
  [ "$(grep -c '^bisync' "$FAKE_CALLS")" -eq 1 ]
}

@test "--dry-run creates nothing and passes --dry-run to rclone" {
  touch "$WORK/local/book.epub" "$WORK/remote/kobo/book.epub"
  run bisync --dry-run
  [ "$status" -eq 0 ]
  [ ! -e "$WORK/local/RCLONE_TEST" ]
  grep -q -- "--dry-run" "$FAKE_CALLS"
}
